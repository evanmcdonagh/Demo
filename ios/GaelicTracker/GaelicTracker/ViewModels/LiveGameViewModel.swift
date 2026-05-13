import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LiveGameViewModel {
    let game: Game
    private let context: ModelContext

    // Clock
    var elapsedSeconds: Int = 0
    var isClockRunning: Bool = false
    private var clockTask: Task<Void, Never>?

    // Active rosters (in-memory for fast UI updates)
    var homeActivePlayers: [PlayerGameStat] = []
    var awayActivePlayers: [PlayerGameStat] = []

    // Sin-bin tracking: playerID → clock second when sin bin expires
    var sinBinExpiry: [UUID: Int] = [:]

    // 2-step event recording state
    var pendingEventType: EventType?
    var pendingTeamSide: EventTeamSide?
    var pendingPlayerStat: PlayerGameStat?
    var showLocationPicker: Bool = false

    // Sheet state
    var showSubstitutionSheet: Bool = false
    var substitutionTeamSide: EventTeamSide = .home

    init(game: Game, context: ModelContext) {
        self.game = game
        self.context = context
        self.elapsedSeconds = game.clockElapsedSeconds
        refreshActivePlayers()
    }

    // MARK: - Clock

    func startClock() {
        guard !isClockRunning else { return }
        isClockRunning = true
        game.clockRunning = true

        if game.status == .notStarted {
            game.status = .firstHalf
        } else if game.status == .halfTime {
            game.status = .secondHalf
        }

        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.elapsedSeconds += 1
                self.game.clockElapsedSeconds = self.elapsedSeconds
                self.checkAndReleaseSinBin()
                try? self.context.save()
            }
        }
    }

    func pauseClock() {
        isClockRunning = false
        game.clockRunning = false
        clockTask?.cancel()
        clockTask = nil
        try? context.save()
    }

    func advanceToHalfTime() {
        pauseClock()
        game.status = .halfTime
        try? context.save()
    }

    func endGame() {
        pauseClock()
        game.status = .fullTime

        // Finalise minutes played for all on-field players
        for stat in game.playerStats where stat.isCurrentlyOnField {
            stat.minutesPlayed = (elapsedSeconds - stat.fieldEntrySecond) / 60
        }
        try? context.save()
    }

    // MARK: - Event Recording (2-step: begin → location picker → confirm)

    func beginScoringEvent(type: EventType, teamSide: EventTeamSide, player: PlayerGameStat) {
        pendingEventType = type
        pendingTeamSide = teamSide
        pendingPlayerStat = player
        showLocationPicker = true
    }

    func confirmLocation(pitchX: Double, pitchY: Double) {
        guard let type = pendingEventType,
              let side = pendingTeamSide,
              let stat = pendingPlayerStat else { return }

        let event = GameEvent(
            clockSeconds: elapsedSeconds,
            eventType: type,
            teamSide: side,
            playerID: stat.playerID,
            playerName: stat.playerName,
            playerJerseyNumber: stat.playerJerseyNumber,
            pitchX: pitchX,
            pitchY: pitchY
        )
        game.events.append(event)
        context.insert(event)

        switch type {
        case .goal:
            stat.goals += 1
        case .point:
            stat.points += 1
        case .twoPointer:
            stat.twoPointers += 1
        case .freeAwarded:
            stat.foulsCommitted += 1
        default:
            break
        }

        pendingEventType = nil
        pendingTeamSide = nil
        pendingPlayerStat = nil

        try? context.save()
    }

    func cancelPendingEvent() {
        pendingEventType = nil
        pendingTeamSide = nil
        pendingPlayerStat = nil
    }

    // MARK: - Cards (instant, no location picker)

    func recordCard(_ cardType: EventType, for stat: PlayerGameStat) {
        let event = GameEvent(
            clockSeconds: elapsedSeconds,
            eventType: cardType,
            teamSide: stat.teamSide,
            playerID: stat.playerID,
            playerName: stat.playerName,
            playerJerseyNumber: stat.playerJerseyNumber
        )
        game.events.append(event)
        context.insert(event)

        switch cardType {
        case .yellowCard:
            stat.yellowCards += 1
        case .blackCard:
            stat.blackCards += 1
            sinBinExpiry[stat.playerID] = elapsedSeconds + 600 // 10 minutes
        case .redCard:
            stat.redCards += 1
            stat.isCurrentlyOnField = false
            stat.minutesPlayed = (elapsedSeconds - stat.fieldEntrySecond) / 60
            refreshActivePlayers()
        default:
            break
        }

        try? context.save()
    }

    // MARK: - Substitutions

    func openSubstitutionSheet(for side: EventTeamSide) {
        substitutionTeamSide = side
        showSubstitutionSheet = true
    }

    func recordSubstitution(
        teamSide: EventTeamSide,
        playerOffStat: PlayerGameStat,
        playerOn: Player
    ) {
        // Mark player off
        playerOffStat.isCurrentlyOnField = false
        playerOffStat.substitutedOffAtSecond = elapsedSeconds
        playerOffStat.minutesPlayed = (elapsedSeconds - playerOffStat.fieldEntrySecond) / 60

        // Create stat for incoming player
        let newStat = PlayerGameStat(
            playerID: playerOn.id,
            playerName: playerOn.name,
            playerJerseyNumber: playerOn.jerseyNumber,
            teamSide: teamSide,
            fieldEntrySecond: elapsedSeconds
        )
        game.playerStats.append(newStat)
        context.insert(newStat)

        // Record substitution
        let sub = Substitution(
            clockSeconds: elapsedSeconds,
            teamSide: teamSide,
            playerOffID: playerOffStat.playerID,
            playerOffName: playerOffStat.playerName,
            playerOffJerseyNumber: playerOffStat.playerJerseyNumber,
            playerOnID: playerOn.id,
            playerOnName: playerOn.name,
            playerOnJerseyNumber: playerOn.jerseyNumber
        )
        game.substitutions.append(sub)
        context.insert(sub)

        refreshActivePlayers()
        try? context.save()
    }

    // MARK: - Sin Bin

    func checkAndReleaseSinBin() {
        for (playerID, expiry) in sinBinExpiry where elapsedSeconds >= expiry {
            sinBinExpiry.removeValue(forKey: playerID)
        }
    }

    func sinBinSecondsRemaining(for playerID: UUID) -> Int? {
        guard let expiry = sinBinExpiry[playerID] else { return nil }
        let remaining = expiry - elapsedSeconds
        return remaining > 0 ? remaining : nil
    }

    func isInSinBin(_ playerID: UUID) -> Bool {
        sinBinSecondsRemaining(for: playerID) != nil
    }

    // MARK: - Roster helpers

    func refreshActivePlayers() {
        homeActivePlayers = game.playerStats
            .filter { $0.teamSide == .home && $0.isCurrentlyOnField }
            .sorted { $0.playerJerseyNumber < $1.playerJerseyNumber }
        awayActivePlayers = game.playerStats
            .filter { $0.teamSide == .away && $0.isCurrentlyOnField }
            .sorted { $0.playerJerseyNumber < $1.playerJerseyNumber }
    }

    func benchPlayers(for teamSide: EventTeamSide, allTeamPlayers: [Player]) -> [Player] {
        let alreadyTrackedIDs = game.playerStats
            .filter { $0.teamSide == teamSide }
            .map { $0.playerID }
        return allTeamPlayers.filter { !alreadyTrackedIDs.contains($0.id) }
    }
}
