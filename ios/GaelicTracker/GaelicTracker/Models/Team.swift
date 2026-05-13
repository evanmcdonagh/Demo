import Foundation
import SwiftData

@Model
final class Team {
    var id: UUID
    var name: String
    var shortName: String
    var colourHex: String
    var format: TeamFormat
    var crestImageData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player]

    var sortedPlayers: [Player] {
        players.sorted { $0.jerseyNumber < $1.jerseyNumber }
    }

    init(name: String, shortName: String, colourHex: String, format: TeamFormat) {
        self.id = UUID()
        self.name = name
        self.shortName = String(shortName.prefix(4)).uppercased()
        self.colourHex = colourHex
        self.format = format
        self.players = []
    }
}
