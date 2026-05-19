import Foundation
import SwiftData

@Model
final class Game {
    var id: UUID
    var date: Date
    var venue: String
    var status: GameStatus
    var format: TeamFormat

    // Team data snapshotted at game creation — survives team edits/deletion
    var homeTeamID: UUID
    var awayTeamID: UUID
    var homeTeamName: String
    var awayTeamName: String
    var homeTeamShortName: String
    var awayTeamShortName: String
    var homeTeamColourHex: String
    var awayTeamColourHex: String
    var homeTeamCrestData: Data?
    var awayTeamCrestData: Data?

    var halfDurationMinutes: Int
    var clockElapsedSeconds: Int
    var clockRunning: Bool
    /// Wall-clock time when the clock was last started; nil when paused.
    var clockStartDate: Date?
    /// Snapshot of `clockElapsedSeconds` at the moment the clock was last started.
    var clockBaseSeconds: Int

    @Relationship(deleteRule: .cascade)
    var events: [GameEvent]

    @Relationship(deleteRule: .cascade)
    var substitutions: [Substitution]

    @Relationship(deleteRule: .cascade)
    var playerStats: [PlayerGameStat]

    // MARK: - Computed score helpers

    var homeGoals: Int { events.filter { $0.teamSide == .home && $0.eventType == .goal }.count }
    var homePoints: Int { events.filter { $0.teamSide == .home && $0.eventType == .point }.count }
    var homeTwoPointers: Int { events.filter { $0.teamSide == .home && $0.eventType == .twoPointer }.count }
    var awayGoals: Int { events.filter { $0.teamSide == .away && $0.eventType == .goal }.count }
    var awayPoints: Int { events.filter { $0.teamSide == .away && $0.eventType == .point }.count }
    var awayTwoPointers: Int { events.filter { $0.teamSide == .away && $0.eventType == .twoPointer }.count }
    var homeTotalPoints: Int { homeGoals * 3 + homeTwoPointers * 2 + homePoints }
    var awayTotalPoints: Int { awayGoals * 3 + awayTwoPointers * 2 + awayPoints }

    var homeScoreDisplay: String { "\(homeGoals)-\(String(format: "%02d", homePoints + homeTwoPointers * 2))" }
    var awayScoreDisplay: String { "\(awayGoals)-\(String(format: "%02d", awayPoints + awayTwoPointers * 2))" }

    var sortedEvents: [GameEvent] { events.sorted { $0.clockSeconds < $1.clockSeconds } }

    var topHomeScorers: [PlayerGameStat] {
        playerStats
            .filter { $0.teamSide == .home && $0.totalPointValue > 0 }
            .sorted { $0.totalPointValue > $1.totalPointValue }
    }

    var topAwayScorers: [PlayerGameStat] {
        playerStats
            .filter { $0.teamSide == .away && $0.totalPointValue > 0 }
            .sorted { $0.totalPointValue > $1.totalPointValue }
    }

    /// Convenience init for two known `Team` records.
    convenience init(
        homeTeam: Team,
        awayTeam: Team,
        venue: String,
        format: TeamFormat,
        halfDurationMinutes: Int = 30
    ) {
        self.init(
            homeTeamID: homeTeam.id,
            homeTeamName: homeTeam.name,
            homeTeamShortName: homeTeam.shortName,
            homeTeamColourHex: homeTeam.colourHex,
            homeTeamCrestData: homeTeam.crestImageData,
            awayTeamID: awayTeam.id,
            awayTeamName: awayTeam.name,
            awayTeamShortName: awayTeam.shortName,
            awayTeamColourHex: awayTeam.colourHex,
            awayTeamCrestData: awayTeam.crestImageData,
            venue: venue,
            format: format,
            halfDurationMinutes: halfDurationMinutes
        )
    }

    /// Designated init using raw team data — used when one or both sides are guest teams.
    init(
        homeTeamID: UUID,
        homeTeamName: String,
        homeTeamShortName: String,
        homeTeamColourHex: String,
        homeTeamCrestData: Data?,
        awayTeamID: UUID,
        awayTeamName: String,
        awayTeamShortName: String,
        awayTeamColourHex: String,
        awayTeamCrestData: Data?,
        venue: String,
        format: TeamFormat,
        halfDurationMinutes: Int = 30
    ) {
        self.id = UUID()
        self.date = Date()
        self.venue = venue
        self.status = .notStarted
        self.format = format
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.homeTeamName = homeTeamName
        self.awayTeamName = awayTeamName
        self.homeTeamShortName = homeTeamShortName
        self.awayTeamShortName = awayTeamShortName
        self.homeTeamColourHex = homeTeamColourHex
        self.awayTeamColourHex = awayTeamColourHex
        self.homeTeamCrestData = homeTeamCrestData
        self.awayTeamCrestData = awayTeamCrestData
        self.halfDurationMinutes = halfDurationMinutes
        self.clockElapsedSeconds = 0
        self.clockRunning = false
        self.clockStartDate = nil
        self.clockBaseSeconds = 0
        self.events = []
        self.substitutions = []
        self.playerStats = []
    }
}
