import SwiftUI
import SwiftData

struct SubstitutionSheetView: View {
    let viewModel: LiveGameViewModel
    let teamSide: EventTeamSide
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var playerOffStat: PlayerGameStat?
    @State private var playerOn: Player?

    private var activePlayers: [PlayerGameStat] {
        teamSide == .home ? viewModel.homeActivePlayers : viewModel.awayActivePlayers
    }

    private var allTeamPlayers: [Player] {
        let descriptor = FetchDescriptor<Team>()
        let teams = (try? context.fetch(descriptor)) ?? []
        let teamID = teamSide == .home ? viewModel.game.homeTeamID : viewModel.game.awayTeamID
        return teams.first(where: { $0.id == teamID })?.sortedPlayers ?? []
    }

    private var benchPlayers: [Player] {
        viewModel.benchPlayers(for: teamSide, allTeamPlayers: allTeamPlayers)
    }

    private var isValid: Bool { playerOffStat != nil && playerOn != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Coming Off") {
                    if activePlayers.isEmpty {
                        Text("No active players").foregroundStyle(.secondary)
                    } else {
                        Picker("Player Off", selection: $playerOffStat) {
                            Text("Select…").tag(Optional<PlayerGameStat>.none)
                            ForEach(activePlayers) { stat in
                                Text("#\(stat.playerJerseyNumber) \(stat.playerName)").tag(Optional(stat))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                Section("Player Coming On") {
                    if benchPlayers.isEmpty {
                        Text("No bench players available").foregroundStyle(.secondary)
                    } else {
                        Picker("Player On", selection: $playerOn) {
                            Text("Select…").tag(Optional<Player>.none)
                            ForEach(benchPlayers) { player in
                                Text("#\(player.jerseyNumber) \(player.name)").tag(Optional(player))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
            }
            .navigationTitle("Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        guard let off = playerOffStat, let on = playerOn else { return }
                        viewModel.recordSubstitution(teamSide: teamSide, playerOffStat: off, playerOn: on)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
