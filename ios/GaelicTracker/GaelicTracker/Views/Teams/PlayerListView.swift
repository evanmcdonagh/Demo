import SwiftUI

struct PlayerListView: View {
    let team: Team
    let viewModel: TeamViewModel

    @State private var showAddPlayer = false
    @State private var editingPlayer: Player?

    var body: some View {
        Group {
            if team.sortedPlayers.isEmpty {
                EmptyStateView(
                    systemImage: "person.fill.badge.plus",
                    title: "No Players",
                    message: "Add players to build your roster.",
                    actionTitle: "Add Player",
                    action: { showAddPlayer = true }
                )
            } else {
                List {
                    ForEach(team.sortedPlayers) { player in
                        HStack {
                            Text("#\(player.jerseyNumber)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color(hex: team.colourHex))
                                .frame(width: 36, alignment: .trailing)
                            Text(player.name)
                                .font(.body)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removePlayer(player)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingPlayer = player
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            PlayerFormView(team: team) { name, number in
                viewModel.addPlayer(to: team, name: name, jerseyNumber: number)
            }
        }
        .sheet(item: $editingPlayer) { player in
            PlayerFormView(team: team, editingPlayer: player) { name, number in
                viewModel.updatePlayer(player, name: name, jerseyNumber: number)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddPlayer = true
                } label: {
                    Label("Add Player", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Roster (\(team.players.count)/\(team.format.maxActivePlayers))")
        .navigationBarTitleDisplayMode(.inline)
    }
}
