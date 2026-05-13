import SwiftUI

struct ActiveRosterView: View {
    let players: [PlayerGameStat]
    let teamColour: Color
    let sinBinExpiry: [UUID: Int]
    let elapsedSeconds: Int
    let isGameLive: Bool
    var onBeginScoring: (EventType, PlayerGameStat) -> Void
    var onCard: (EventType, PlayerGameStat) -> Void
    var onSubstitution: (PlayerGameStat) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(players) { stat in
                    playerRow(stat)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func playerRow(_ stat: PlayerGameStat) -> some View {
        let inSinBin = sinBinRemaining(stat.playerID) != nil
        let isDisabled = !isGameLive || stat.redCards > 0

        VStack(alignment: .leading, spacing: 4) {
            // Name + card badge + score
            HStack(spacing: 6) {
                Text("#\(stat.playerJerseyNumber)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(teamColour)
                    .frame(width: 28, alignment: .trailing)
                Text(stat.playerName)
                    .font(.subheadline)
                    .lineLimit(1)
                CardBadgeView(status: stat.currentCardStatus)
                Spacer()
                if stat.totalPointValue > 0 {
                    Text(stat.scoreDisplay)
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(teamColour)
                }
            }

            // Sin bin countdown
            if inSinBin, let remaining = sinBinRemaining(stat.playerID) {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption)
                    Text("Sin Bin: \(remaining.clockString) remaining")
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.orange)
                .padding(.leading, 34)
            }

            // Action buttons
            if !inSinBin && !isDisabled {
                HStack(spacing: 6) {
                    Spacer().frame(width: 28)
                    actionButton("G", color: .green) {
                        onBeginScoring(.goal, stat)
                    }
                    actionButton("2", color: .purple) {
                        onBeginScoring(.twoPointer, stat)
                    }
                    actionButton("P", color: .blue) {
                        onBeginScoring(.point, stat)
                    }
                    actionButton("F", color: .orange) {
                        onBeginScoring(.freeAwarded, stat)
                    }
                    cardMenu(stat)
                    Spacer()
                    Button {
                        onSubstitution(stat)
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .tint(.gray)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .opacity(inSinBin || isDisabled ? 0.55 : 1.0)
    }

    @ViewBuilder
    private func actionButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .font(.caption.bold())
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .tint(color)
    }

    @ViewBuilder
    private func cardMenu(_ stat: PlayerGameStat) -> some View {
        Menu {
            Button("Yellow Card") { onCard(.yellowCard, stat) }
            Button("Black Card") { onCard(.blackCard, stat) }
            Button("Red Card", role: .destructive) { onCard(.redCard, stat) }
        } label: {
            Image(systemName: "rectangle.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .tint(.secondary)
    }

    private func sinBinRemaining(_ playerID: UUID) -> Int? {
        guard let expiry = sinBinExpiry[playerID] else { return nil }
        let r = expiry - elapsedSeconds
        return r > 0 ? r : nil
    }
}
