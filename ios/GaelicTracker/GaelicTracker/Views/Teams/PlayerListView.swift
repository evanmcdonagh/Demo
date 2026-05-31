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
                        HStack(spacing: 10) {
                            // Jersey number badge
                            Text("#\(player.jerseyNumber)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color(hex: team.colourHex))
                                .frame(width: 36, alignment: .trailing)

                            // Name + position
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.body)
                                if let pos = player.position {
                                    Text(pos.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // Position abbreviation badge
                            if let pos = player.position {
                                Text(pos.abbreviation)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color(hex: team.colourHex))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: team.colourHex).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
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
            PlayerFormView(team: team) { name, number, position in
                viewModel.addPlayer(to: team, name: name, jerseyNumber: number, position: position)
            }
        }
        .sheet(item: $editingPlayer) { player in
            PlayerFormView(team: team, editingPlayer: player) { name, number, position in
                viewModel.updatePlayer(player, name: name, jerseyNumber: number, position: position)
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
