import SwiftUI

struct ActiveRosterView: View {
    let players: [PlayerGameStat]
    let teamColour: Color
    let sinBinExpiry: [UUID: Int]
    let elapsedSeconds: Int
    let isGameLive: Bool
    var onBeginScoring: (EventType, PlayerGameStat) -> Void   // events needing pitch location
    var onInstantEvent: (EventType, PlayerGameStat) -> Void   // events without pitch location (KO, cards)
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
                    // Primary scoring
                    actionButton("G", color: .green)  { onBeginScoring(.goal, stat) }
                    actionButton("2", color: .purple)  { onBeginScoring(.twoPointer, stat) }
                    actionButton("P", color: .blue)    { onBeginScoring(.point, stat) }
                    // Secondary events + cards menu
                    eventsMenu(stat)
                    Spacer()
                    // Substitution
                    Button { onSubstitution(stat) } label: {
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

    /// Combined menu for non-scoring events and cards.
    @ViewBuilder
    private func eventsMenu(_ stat: PlayerGameStat) -> some View {
        Menu {
            // Frees & kickouts
            Button {
                onBeginScoring(.freeAwarded, stat)
            } label: {
                Label("Free Won", systemImage: EventType.freeAwarded.iconName)
            }
            Button {
                onBeginScoring(.freeConceded, stat)
            } label: {
                Label("Free Conceded", systemImage: EventType.freeConceded.iconName)
            }
            Button {
                onInstantEvent(.kickoutWon, stat)
            } label: {
                Label("Kickout Won", systemImage: EventType.kickoutWon.iconName)
            }

            Divider()

            // Cards
            Button("Yellow Card") { onCard(.yellowCard, stat) }
            Button("Black Card")  { onCard(.blackCard, stat) }
            Button("Red Card", role: .destructive) { onCard(.redCard, stat) }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
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
