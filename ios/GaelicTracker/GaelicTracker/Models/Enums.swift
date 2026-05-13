import Foundation

enum TeamFormat: Int, Codable, CaseIterable {
    case sevens = 7
    case nines = 9
    case elevens = 11
    case thirteens = 13
    case fifteens = 15

    var displayName: String {
        switch self {
        case .sevens: return "7-a-Side"
        case .nines: return "9-a-Side"
        case .elevens: return "11-a-Side"
        case .thirteens: return "13-a-Side"
        case .fifteens: return "15-a-Side (Standard)"
        }
    }

    var maxActivePlayers: Int { rawValue }
}

enum GameStatus: String, Codable {
    case notStarted
    case firstHalf
    case halfTime
    case secondHalf
    case fullTime

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .firstHalf: return "1st Half"
        case .halfTime: return "Half Time"
        case .secondHalf: return "2nd Half"
        case .fullTime: return "Full Time"
        }
    }

    var isLive: Bool {
        self == .firstHalf || self == .secondHalf
    }
}

enum EventType: String, Codable {
    case goal
    case point
    case twoPointer
    case freeAwarded
    case yellowCard
    case blackCard
    case redCard

    var displayName: String {
        switch self {
        case .goal: return "Goal"
        case .point: return "Point"
        case .twoPointer: return "Two Pointer"
        case .freeAwarded: return "Free Awarded"
        case .yellowCard: return "Yellow Card"
        case .blackCard: return "Black Card"
        case .redCard: return "Red Card"
        }
    }

    var isCard: Bool {
        self == .yellowCard || self == .blackCard || self == .redCard
    }

    var needsPitchLocation: Bool {
        self == .goal || self == .point || self == .twoPointer || self == .freeAwarded
    }

    var pointValue: Int {
        switch self {
        case .goal: return 3
        case .twoPointer: return 2
        case .point: return 1
        default: return 0
        }
    }

    /// SF Symbol name used in event logs and legends.
    var iconName: String {
        switch self {
        case .goal:        return "sportscourt.fill"
        case .point:       return "arrow.up.circle.fill"
        case .twoPointer:  return "2.circle.fill"
        case .freeAwarded: return "exclamationmark.circle.fill"
        case .yellowCard:  return "rectangle.fill"
        case .blackCard:   return "rectangle.fill"
        case .redCard:     return "rectangle.fill"
        }
    }

    /// Canonical display colour used in event logs and legends.
    var displayColor: String {
        switch self {
        case .goal:        return "green"
        case .point:       return "blue"
        case .twoPointer:  return "purple"
        case .freeAwarded: return "orange"
        case .yellowCard:  return "yellow"
        case .blackCard:   return "black"
        case .redCard:     return "red"
        }
    }
}

enum EventTeamSide: String, Codable {
    case home
    case away
}

enum CardStatus: String, Codable {
    case none
    case yellow
    case black
    case red
}
