import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var jerseyNumber: Int

    var team: Team?

    init(name: String, jerseyNumber: Int) {
        self.id = UUID()
        self.name = name
        self.jerseyNumber = jerseyNumber
    }
}
