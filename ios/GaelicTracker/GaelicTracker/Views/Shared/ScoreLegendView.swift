import SwiftUI

extension EventType {
    var swiftUIColor: Color {
        switch displayColor {
        case "green":  return .green
        case "blue":   return .blue
        case "purple": return .purple
        case "teal":   return .teal
        case "mint":   return .mint
        case "orange": return .orange
        case "yellow": return .yellow
        case "black":  return .primary   // .black renders poorly in dark mode
        case "red":    return .red
        default:       return .secondary
        }
    }
}

/// A compact legend showing every event type with its icon, colour, and label.
struct ScoreLegendView: View {
    /// Show only scoring events (goal, point, twoPointer) or all event types.
    var scopeAll: Bool = true

    private var items: [EventType] {
        scopeAll
            ? [.goal, .twoPointer, .point,
               .freeAwarded, .freeConceded, .kickoutWon,
               .yellowCard, .blackCard, .redCard]
            : [.goal, .twoPointer, .point]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Legend")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(items, id: \.self) { type in
                    LegendItem(type: type)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

private struct LegendItem: View {
    let type: EventType

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.iconName)
                .foregroundStyle(type.swiftUIColor)
                .frame(width: 18)
            Text(type.displayName)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}
