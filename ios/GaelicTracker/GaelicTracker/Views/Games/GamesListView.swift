import SwiftUI
import SwiftData

struct GamesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.date, order: .reverse) private var games: [Game]

    @State private var showCreateGame = false
    @State private var activeGame: Game?

    private var gameViewModel: GameViewModel { GameViewModel(context: context) }

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    EmptyStateView(
                        systemImage: "sportscourt",
                        title: "No Games Yet",
                        message: "Set up your first game to start tracking.",
                        actionTitle: "New Game",
                        action: { showCreateGame = true }
                    )
                } else {
                    List {
                        ForEach(games) { game in
                            gameRow(game)
                        }
                        .onDelete { offsets in
                            offsets.map { games[$0] }.forEach { gameViewModel.deleteGame($0) }
                        }
                    }
                }
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateGame = true
                    } label: {
                        Label("New Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGame) {
                GameSetupView(viewModel: gameViewModel) { game in
                    activeGame = game
                }
            }
            .navigationDestination(item: $activeGame) { game in
                LiveGameView(game: game)
            }
        }
    }

    @ViewBuilder
    private func gameRow(_ game: Game) -> some View {
        let isLive = game.status.isLive || game.status == .halfTime

        NavigationLink {
            if game.status == .fullTime || (!isLive && game.status != .notStarted) {
                GameSummaryView(game: game)
            } else {
                LiveGameView(game: game)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        CrestOrInitialsView(
                            crestData: game.homeTeamCrestData,
                            shortName: game.homeTeamShortName,
                            colourHex: game.homeTeamColourHex,
                            size: 20
                        )
                        Text(game.homeTeamShortName)
                            .font(.subheadline.bold())
                        Text(game.homeScoreDisplay)
                            .font(.subheadline.monospacedDigit())
                        Text("–").foregroundStyle(.secondary)
                        Text(game.awayScoreDisplay)
                            .font(.subheadline.monospacedDigit())
                        Text(game.awayTeamShortName)
                            .font(.subheadline.bold())
                        CrestOrInitialsView(
                            crestData: game.awayTeamCrestData,
                            shortName: game.awayTeamShortName,
                            colourHex: game.awayTeamColourHex,
                            size: 20
                        )
                    }
                    HStack(spacing: 6) {
                        statusBadge(game)
                        if !game.venue.isEmpty {
                            Text(game.venue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(game.date.shortGameDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                gameViewModel.deleteGame(game)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if game.status == .fullTime {
                Button {
                    ShareExporter.shareGame(game)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.blue)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ game: Game) -> some View {
        let (label, color): (String, Color) = {
            switch game.status {
            case .notStarted: return ("Not Started", .secondary)
            case .firstHalf: return ("1st Half", .green)
            case .halfTime: return ("HT", .orange)
            case .secondHalf: return ("2nd Half", .green)
            case .fullTime: return ("FT", .secondary)
            }
        }()
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}
