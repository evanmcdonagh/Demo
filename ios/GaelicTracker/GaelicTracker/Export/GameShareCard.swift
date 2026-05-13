import SwiftUI

/// A self-contained SwiftUI view rendered to an image for social media sharing.
struct GameShareCard: View {
    let game: Game

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sportscourt.fill")
                    .foregroundStyle(.white)
                Text("GaelicTracker")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(game.date.shortGameDate)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))

            // Scoreboard
            HStack(spacing: 0) {
                // Home
                teamScoreSection(
                    crestData: game.homeTeamCrestData,
                    shortName: game.homeTeamShortName,
                    name: game.homeTeamName,
                    colourHex: game.homeTeamColourHex,
                    goals: game.homeGoals,
                    points: game.homePoints,
                    twoPointers: game.homeTwoPointers,
                    alignment: .leading
                )

                Text("v")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 30)

                // Away
                teamScoreSection(
                    crestData: game.awayTeamCrestData,
                    shortName: game.awayTeamShortName,
                    name: game.awayTeamName,
                    colourHex: game.awayTeamColourHex,
                    goals: game.awayGoals,
                    points: game.awayPoints,
                    twoPointers: game.awayTwoPointers,
                    alignment: .trailing
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: game.homeTeamColourHex), Color(hex: game.awayTeamColourHex)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Status + Venue
            HStack {
                Label(game.status.displayName, systemImage: "flag.checkered")
                    .font(.caption.bold())
                Spacer()
                if !game.venue.isEmpty {
                    Label(game.venue, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            Divider()

            // Top Scorers
            HStack(alignment: .top, spacing: 0) {
                scorersColumn(
                    side: .home,
                    colourHex: game.homeTeamColourHex,
                    scorers: Array(game.topHomeScorers.prefix(3))
                )
                Divider()
                scorersColumn(
                    side: .away,
                    colourHex: game.awayTeamColourHex,
                    scorers: Array(game.topAwayScorers.prefix(3))
                )
            }
            .background(Color(.systemBackground))

            // Goal minute log
            let goalEvents = game.sortedEvents.filter { $0.eventType == .goal }
            if !goalEvents.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(goalEvents) { ev in
                            goalChip(event: ev)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }

            // Footer
            HStack {
                Spacer()
                Text("Made with GaelicTracker")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
        }
        .frame(width: 360)
        .cornerRadius(16)
        .shadow(radius: 8)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func teamScoreSection(
        crestData: Data?,
        shortName: String,
        name: String,
        colourHex: String,
        goals: Int,
        points: Int,
        twoPointers: Int = 0,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            CrestOrInitialsView(
                crestData: crestData,
                shortName: shortName,
                colourHex: colourHex,
                size: 48
            )
            Text(shortName)
                .font(.headline.bold())
                .foregroundStyle(.white)
            ScoreFormatView(goals: goals, points: points, twoPointers: twoPointers, font: .title.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    @ViewBuilder
    private func scorersColumn(side: EventTeamSide, colourHex: String, scorers: [PlayerGameStat]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(side == .home ? "Home Scorers" : "Away Scorers")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: colourHex))
                .padding(.bottom, 2)
            if scorers.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(scorers) { stat in
                    HStack {
                        Text(stat.playerName.components(separatedBy: " ").last ?? stat.playerName)
                            .font(.caption)
                        Spacer()
                        Text(stat.scoreDisplay)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalChip(event: GameEvent) -> some View {
        HStack(spacing: 3) {
            if let name = event.playerName {
                Text(name.components(separatedBy: " ").last ?? name)
                    .font(.system(size: 10))
            }
            Text(event.minuteDisplay)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(4)
    }
}

// MARK: - Simple flow layout for goal chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows.last!.isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(view)
            rowWidth += size.width + spacing
        }
        return rows
    }
}
