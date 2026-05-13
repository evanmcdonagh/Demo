import SwiftUI

/// Displays a Gaelic score in "G-PP (Total)" format.
/// Two-pointer values are folded into the displayed points total so the score visibly
/// increases on screen (e.g. 1 two-pointer shows as +2 in the PP column).
struct ScoreFormatView: View {
    let goals: Int
    let points: Int
    var twoPointers: Int = 0
    var font: Font = .title2.bold()
    var showTotal: Bool = true

    /// Points visible in the G-PP display: regular points + 2-pointer value.
    var displayedPoints: Int { points + twoPointers * 2 }
    var total: Int { goals * 3 + displayedPoints }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(goals)-\(String(format: "%02d", displayedPoints))")
                .font(font)
            if showTotal {
                Text("(\(total))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
