import Foundation

// MARK: - Gaelic Football Positions

enum GaelicPosition: String, Codable, CaseIterable {
    case goalkeeper
    case rightCornerBack
    case fullBack
    case leftCornerBack
    case rightHalfBack
    case centreHalfBack
    case leftHalfBack
    case rightMidfield
    case leftMidfield
    case rightHalfForward
    case centreHalfForward
    case leftHalfForward
    case rightCornerForward
    case fullForward
    case leftCornerForward

    var displayName: String {
        switch self {
        case .goalkeeper:         return "Goalkeeper"
        case .rightCornerBack:    return "Right Corner Back"
        case .fullBack:           return "Full Back"
        case .leftCornerBack:     return "Left Corner Back"
        case .rightHalfBack:      return "Right Half Back"
        case .centreHalfBack:     return "Centre Half Back"
        case .leftHalfBack:       return "Left Half Back"
        case .rightMidfield:      return "Right Midfield"
        case .leftMidfield:       return "Left Midfield"
        case .rightHalfForward:   return "Right Half Forward"
        case .centreHalfForward:  return "Centre Half Forward"
        case .leftHalfForward:    return "Left Half Forward"
        case .rightCornerForward: return "Right Corner Forward"
        case .fullForward:        return "Full Forward"
        case .leftCornerForward:  return "Left Corner Forward"
        }
    }

    var abbreviation: String {
        switch self {
        case .goalkeeper:         return "GK"
        case .rightCornerBack:    return "RCB"
        case .fullBack:           return "FB"
        case .leftCornerBack:     return "LCB"
        case .rightHalfBack:      return "RHB"
        case .centreHalfBack:     return "CHB"
        case .leftHalfBack:       return "LHB"
        case .rightMidfield:      return "RM"
        case .leftMidfield:       return "LM"
        case .rightHalfForward:   return "RHF"
        case .centreHalfForward:  return "CHF"
        case .leftHalfForward:    return "LHF"
        case .rightCornerForward: return "RCF"
        case .fullForward:        return "FF"
        case .leftCornerForward:  return "LCF"
        }
    }

    /// Returns the standard GAA position for a given jersey number (1–15).
    /// Works for all formats; smaller formats naturally use only the lower-numbered positions.
    static func suggested(for jerseyNumber: Int) -> GaelicPosition? {
        let map: [Int: GaelicPosition] = [
             1: .goalkeeper,
             2: .rightCornerBack,
             3: .fullBack,
             4: .leftCornerBack,
             5: .rightHalfBack,
             6: .centreHalfBack,
             7: .leftHalfBack,
             8: .rightMidfield,
             9: .leftMidfield,
            10: .rightHalfForward,
            11: .centreHalfForward,
            12: .leftHalfForward,
            13: .rightCornerForward,
            14: .fullForward,
            15: .leftCornerForward,
        ]
        return map[jerseyNumber]
    }
}

// MARK: - Team Format

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
    case freeAwarded    // free won by this player's team (opponent fouled)
    case freeConceded   // free given away by this player (this player fouled)
    case kickoutWon     // player won a kick-out
    case yellowCard
    case blackCard
    case redCard

    var displayName: String {
        switch self {
        case .goal:         return "Goal"
        case .point:        return "Point"
        case .twoPointer:   return "Two Pointer"
        case .freeAwarded:  return "Free Won"
        case .freeConceded: return "Free Conceded"
        case .kickoutWon:   return "Kickout Won"
        case .yellowCard:   return "Yellow Card"
        case .blackCard:    return "Black Card"
        case .redCard:      return "Red Card"
        }
    }

    var isCard: Bool {
        self == .yellowCard || self == .blackCard || self == .redCard
    }

    /// Whether this event type requires the user to tap a pitch location.
    var needsPitchLocation: Bool {
        switch self {
        case .goal, .point, .twoPointer, .freeAwarded, .freeConceded: return true
        default: return false
        }
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
        case .goal:         return "sportscourt.fill"
        case .point:        return "arrow.up.circle.fill"
        case .twoPointer:   return "2.circle.fill"
        case .freeAwarded:  return "hand.thumbsup.fill"
        case .freeConceded: return "hand.raised.fill"
        case .kickoutWon:   return "arrow.up.forward.circle.fill"
        case .yellowCard:   return "rectangle.fill"
        case .blackCard:    return "rectangle.fill"
        case .redCard:      return "rectangle.fill"
        }
    }

    /// Canonical display colour used in event logs and legends.
    var displayColor: String {
        switch self {
        case .goal:         return "green"
        case .point:        return "blue"
        case .twoPointer:   return "purple"
        case .freeAwarded:  return "teal"
        case .freeConceded: return "orange"
        case .kickoutWon:   return "mint"
        case .yellowCard:   return "yellow"
        case .blackCard:    return "black"
        case .redCard:      return "red"
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
