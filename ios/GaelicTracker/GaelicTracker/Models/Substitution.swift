import Foundation
import SwiftData

@Model
final class Substitution {
    var id: UUID
    var clockSeconds: Int
    var teamSide: EventTeamSide

    var playerOffID: UUID
    var playerOffName: String
    var playerOffJerseyNumber: Int

    var playerOnID: UUID
    var playerOnName: String
    var playerOnJerseyNumber: Int

    init(
        clockSeconds: Int,
        teamSide: EventTeamSide,
        playerOffID: UUID,
        playerOffName: String,
        playerOffJerseyNumber: Int,
        playerOnID: UUID,
        playerOnName: String,
        playerOnJerseyNumber: Int
    ) {
        self.id = UUID()
        self.clockSeconds = clockSeconds
        self.teamSide = teamSide
        self.playerOffID = playerOffID
        self.playerOffName = playerOffName
        self.playerOffJerseyNumber = playerOffJerseyNumber
        self.playerOnID = playerOnID
        self.playerOnName = playerOnName
        self.playerOnJerseyNumber = playerOnJerseyNumber
    }
}
