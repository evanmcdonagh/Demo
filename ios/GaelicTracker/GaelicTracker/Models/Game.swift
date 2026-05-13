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

    init(
        homeTeam: Team,
        awayTeam: Team,
        venue: String,
        format: TeamFormat,
        halfDurationMinutes: Int = 30
    ) {
        self.id = UUID()
        self.date = Date()
        self.venue = venue
        self.status = .notStarted
        self.format = format
        self.homeTeamID = homeTeam.id
        self.awayTeamID = awayTeam.id
        self.homeTeamName = homeTeam.name
        self.awayTeamName = awayTeam.name
        self.homeTeamShortName = homeTeam.shortName
        self.awayTeamShortName = awayTeam.shortName
        self.homeTeamColourHex = homeTeam.colourHex
        self.awayTeamColourHex = awayTeam.colourHex
        self.homeTeamCrestData = homeTeam.crestImageData
        self.awayTeamCrestData = awayTeam.crestImageData
        self.halfDurationMinutes = halfDurationMinutes
        self.clockElapsedSeconds = 0
        self.clockRunning = false
        self.events = []
        self.substitutions = []
        self.playerStats = []
    }
}
