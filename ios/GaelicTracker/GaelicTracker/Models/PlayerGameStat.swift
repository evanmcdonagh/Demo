import Foundation
import SwiftData

@Model
final class PlayerGameStat {
    var id: UUID
    var playerID: UUID
    var playerName: String
    var playerJerseyNumber: Int
    var teamSide: EventTeamSide

    var goals: Int
    var points: Int
    var twoPointers: Int
    var yellowCards: Int
    var blackCards: Int
    var redCards: Int
    var foulsCommitted: Int

    var isCurrentlyOnField: Bool
    var fieldEntrySecond: Int
    var minutesPlayed: Int
    var substitutedOffAtSecond: Int?

    var totalPointValue: Int { goals * 3 + twoPointers * 2 + points }

    /// Displayed points: regular points + two-pointer value, matching the main scoreboard convention.
    var displayedPoints: Int { points + twoPointers * 2 }

    var scoreDisplay: String { "\(goals)-\(displayedPoints)" }

    var currentCardStatus: CardStatus {
        if redCards > 0 { return .red }
        if blackCards > 0 { return .black }
        if yellowCards > 0 { return .yellow }
        return .none
    }

    init(playerID: UUID, playerName: String, playerJerseyNumber: Int, teamSide: EventTeamSide, fieldEntrySecond: Int = 0) {
        self.id = UUID()
        self.playerID = playerID
        self.playerName = playerName
        self.playerJerseyNumber = playerJerseyNumber
        self.teamSide = teamSide
        self.goals = 0
        self.points = 0
        self.twoPointers = 0
        self.yellowCards = 0
        self.blackCards = 0
        self.redCards = 0
        self.foulsCommitted = 0
        self.isCurrentlyOnField = true
        self.fieldEntrySecond = fieldEntrySecond
        self.minutesPlayed = 0
    }
}
