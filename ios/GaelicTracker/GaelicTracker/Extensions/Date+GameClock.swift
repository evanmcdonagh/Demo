import Foundation

extension Int {
    /// Formats seconds as "MM:SS" clock string.
    var clockString: String {
        let m = self / 60
        let s = self % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Formats seconds as "M'" minute marker string.
    var minuteString: String { "\(self / 60)'" }
}

extension Date {
    var shortGameDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }

    var gameDateTime: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: self)
    }
}
