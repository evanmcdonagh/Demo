import SwiftUI

struct ScoreboardView: View {
    let game: Game
    let elapsedSeconds: Int

    var body: some View {
        HStack(spacing: 0) {
            // Home
            teamScoreBlock(
                crestData: game.homeTeamCrestData,
                shortName: game.homeTeamShortName,
                colourHex: game.homeTeamColourHex,
                goals: game.homeGoals,
                points: game.homePoints,
                twoPointers: game.homeTwoPointers,
                alignment: .leading
            )

            // Status pill in centre
            VStack(spacing: 2) {
                Text(game.status.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(game.status).opacity(0.2))
                    .foregroundStyle(statusColor(game.status))
                    .cornerRadius(4)
                Text(elapsedSeconds.clockString)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72)

            // Away
            teamScoreBlock(
                crestData: game.awayTeamCrestData,
                shortName: game.awayTeamShortName,
                colourHex: game.awayTeamColourHex,
                goals: game.awayGoals,
                points: game.awayPoints,
                twoPointers: game.awayTwoPointers,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private func teamScoreBlock(
        crestData: Data?,
        shortName: String,
        colourHex: String,
        goals: Int,
        points: Int,
        twoPointers: Int,
        alignment: HorizontalAlignment
    ) -> some View {
        HStack(spacing: 8) {
            if alignment == .trailing {
                ScoreFormatView(goals: goals, points: points, twoPointers: twoPointers, font: .title3.bold())
            }
            VStack(alignment: alignment, spacing: 2) {
                CrestOrInitialsView(
                    crestData: crestData,
                    shortName: shortName,
                    colourHex: colourHex,
                    size: 28
                )
                Text(shortName)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: colourHex))
            }
            if alignment == .leading {
                ScoreFormatView(goals: goals, points: points, twoPointers: twoPointers, font: .title3.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    private func statusColor(_ status: GameStatus) -> Color {
        switch status {
        case .firstHalf, .secondHalf: return .green
        case .halfTime: return .orange
        case .fullTime: return .secondary
        case .notStarted: return .secondary
        }
    }
}
