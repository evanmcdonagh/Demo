import SwiftUI

struct TeamDetailView: View {
    let team: Team
    let viewModel: TeamViewModel

    @State private var showEditTeam = false
    @State private var showGenerateConfirm = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    CrestOrInitialsView(
                        crestData: team.crestImageData,
                        shortName: team.shortName,
                        colourHex: team.colourHex,
                        size: 64
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.name)
                            .font(.title3.bold())
                        Text(team.format.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Circle()
                                .fill(Color(hex: team.colourHex))
                                .frame(width: 12, height: 12)
                            Text(team.colourHex)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Roster (\(team.players.count) players)") {
                if team.sortedPlayers.isEmpty {
                    Text("No players added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(team.sortedPlayers) { player in
                        HStack {
                            Text("#\(player.jerseyNumber)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color(hex: team.colourHex))
                                .frame(width: 36, alignment: .trailing)
                            Text(player.name)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removePlayer(player)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(team.shortName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    PlayerListView(team: team, viewModel: viewModel)
                } label: {
                    Label("Manage Roster", systemImage: "person.3")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Edit Team") { showEditTeam = true }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Generate Numbered Squad") { showGenerateConfirm = true }
            }
        }
        .confirmationDialog(
            "Generate Numbered Squad?",
            isPresented: $showGenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace with #1–\(team.format.maxActivePlayers)", role: .destructive) {
                viewModel.generateNumberedSquad(for: team)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all current players with numbered placeholders (#1–\(team.format.maxActivePlayers)). Use this for tracking games against unknown opponents.")
        }
        .sheet(isPresented: $showEditTeam) {
            TeamFormView(editingTeam: team) { name, shortName, colour, format, crest in
                viewModel.updateTeam(team, name: name, shortName: shortName, colourHex: colour, format: format, crestImageData: crest)
            }
        }
    }
}
