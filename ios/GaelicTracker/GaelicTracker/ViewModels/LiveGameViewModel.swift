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
        // Restore elapsed time from wall-clock (covers backgrounded / screen-locked state)
        self.elapsedSeconds = Self.wallClockElapsed(game: game)
        refreshActivePlayers()
        // If the clock was running when the app was last killed/backgrounded, restart the tick loop
        if game.clockRunning {
            isClockRunning = true
            startTickLoop()
        }
    }

    // MARK: - Clock (wall-clock based)

    /// Computes the true elapsed seconds using wall-clock arithmetic when the clock is running.
    private static func wallClockElapsed(game: Game) -> Int {
        guard game.clockRunning, let startDate = game.clockStartDate else {
            return game.clockElapsedSeconds
        }
        return game.clockBaseSeconds + max(0, Int(Date().timeIntervalSince(startDate)))
    }

    /// Syncs `elapsedSeconds` from wall-clock. Call on foreground restore or timer tick.
    func syncFromWallClock() {
        guard isClockRunning, let startDate = game.clockStartDate else { return }
        elapsedSeconds = game.clockBaseSeconds + max(0, Int(Date().timeIntervalSince(startDate)))
        game.clockElapsedSeconds = elapsedSeconds
    }

    func startClock() {
        guard !isClockRunning else { return }
        isClockRunning = true
        game.clockRunning = true
        game.clockBaseSeconds = elapsedSeconds
        game.clockStartDate = Date()

        if game.status == .notStarted {
            game.status = .firstHalf
        } else if game.status == .halfTime {
            game.status = .secondHalf
        }

        startTickLoop()
        try? context.save()
    }

    func pauseClock() {
        syncFromWallClock()
        isClockRunning = false
        game.clockRunning = false
        game.clockStartDate = nil
        clockTask?.cancel()
        clockTask = nil
        try? context.save()
    }

    private func startTickLoop() {
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.syncFromWallClock()
                self.checkAndReleaseSinBin()
                try? self.context.save()
            }
        }
    }

    func advanceToHalfTime() {
        pauseClock()
        game.status = .halfTime
        try? context.save()
    }

    func endGame() {
        pauseClock()
        game.status = .fullTime
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
        case .goal:         stat.goals += 1
        case .point:        stat.points += 1
        case .twoPointer:   stat.twoPointers += 1
        case .freeAwarded:  stat.foulsCommitted += 1    // freesWon counter
        case .freeConceded: stat.freesConceded += 1
        default: break
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

    // MARK: - Instant events (no location picker)

    /// Records an event that does not require a pitch location (kickout won, cards).
    func recordInstantEvent(_ type: EventType, for stat: PlayerGameStat) {
        let event = GameEvent(
            clockSeconds: elapsedSeconds,
            eventType: type,
            teamSide: stat.teamSide,
            playerID: stat.playerID,
            playerName: stat.playerName,
            playerJerseyNumber: stat.playerJerseyNumber
        )
        game.events.append(event)
        context.insert(event)

        switch type {
        case .kickoutWon: stat.kickoutsWon += 1
        default: break
        }
        try? context.save()
    }

    // MARK: - Cards

    func recordCard(_ cardType: EventType, for stat: PlayerGameStat) {
        recordInstantEvent(cardType, for: stat)

        switch cardType {
        case .yellowCard:
            stat.yellowCards += 1
        case .blackCard:
            stat.blackCards += 1
            sinBinExpiry[stat.playerID] = elapsedSeconds + 600
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

    // MARK: - Delete event (undo)

    /// Deletes an event and reverses its contribution to the relevant `PlayerGameStat`.
    func deleteEvent(_ event: GameEvent) {
        // Reverse stat contribution
        if let playerID = event.playerID,
           let stat = game.playerStats.first(where: {
               $0.playerID == playerID && $0.teamSide == event.teamSide
           }) {
            switch event.eventType {
            case .goal:         stat.goals         = max(0, stat.goals - 1)
            case .point:        stat.points        = max(0, stat.points - 1)
            case .twoPointer:   stat.twoPointers   = max(0, stat.twoPointers - 1)
            case .freeAwarded:  stat.foulsCommitted = max(0, stat.foulsCommitted - 1)
            case .freeConceded: stat.freesConceded = max(0, stat.freesConceded - 1)
            case .kickoutWon:   stat.kickoutsWon   = max(0, stat.kickoutsWon - 1)
            case .yellowCard:   stat.yellowCards   = max(0, stat.yellowCards - 1)
            case .blackCard:    stat.blackCards    = max(0, stat.blackCards - 1)
            case .redCard:
                stat.redCards = max(0, stat.redCards - 1)
                // Restore player to field if red-card deletion brings them back
                if stat.redCards == 0 {
                    stat.isCurrentlyOnField = true
                    refreshActivePlayers()
                }
            }
        }

        game.events.removeAll { $0.id == event.id }
        context.delete(event)
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
        playerOffStat.isCurrentlyOnField = false
        playerOffStat.substitutedOffAtSecond = elapsedSeconds
        playerOffStat.minutesPlayed = (elapsedSeconds - playerOffStat.fieldEntrySecond) / 60

        let newStat = PlayerGameStat(
            playerID: playerOn.id,
            playerName: playerOn.name,
            playerJerseyNumber: playerOn.jerseyNumber,
            teamSide: teamSide,
            fieldEntrySecond: elapsedSeconds
        )
        game.playerStats.append(newStat)
        context.insert(newStat)

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
