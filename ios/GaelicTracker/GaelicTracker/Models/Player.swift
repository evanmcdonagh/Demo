import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var jerseyNumber: Int
    var position: GaelicPosition?

    var team: Team?

    init(name: String, jerseyNumber: Int, position: GaelicPosition? = nil) {
        self.id = UUID()
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.position = position
    }
}
