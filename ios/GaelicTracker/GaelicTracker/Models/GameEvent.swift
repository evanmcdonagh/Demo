import Foundation
import SwiftData

@Model
final class GameEvent {
    var id: UUID
    var clockSeconds: Int
    var eventType: EventType
    var teamSide: EventTeamSide

    var playerID: UUID?
    var playerName: String?
    var playerJerseyNumber: Int?

    // Normalised 0.0–1.0 pitch coordinates; nil for cards
    var pitchX: Double?
    var pitchY: Double?

    init(
        clockSeconds: Int,
        eventType: EventType,
        teamSide: EventTeamSide,
        playerID: UUID? = nil,
        playerName: String? = nil,
        playerJerseyNumber: Int? = nil,
        pitchX: Double? = nil,
        pitchY: Double? = nil
    ) {
        self.id = UUID()
        self.clockSeconds = clockSeconds
        self.eventType = eventType
        self.teamSide = teamSide
        self.playerID = playerID
        self.playerName = playerName
        self.playerJerseyNumber = playerJerseyNumber
        self.pitchX = pitchX
        self.pitchY = pitchY
    }

    var clockDisplayTime: String {
        let minutes = clockSeconds / 60
        let seconds = clockSeconds % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var minuteDisplay: String {
        "\(clockSeconds / 60)'"
    }
}
