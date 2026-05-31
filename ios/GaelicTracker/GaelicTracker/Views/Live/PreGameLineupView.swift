import SwiftUI

/// Sheet for editing the starting lineup and match-day jersey numbers before kick-off.
/// Only intended for use while `game.status == .notStarted`.
struct PreGameLineupView: View {
    @Environment(\.dismiss) private var dismiss
    let vm: LiveGameViewModel

    var body: some View {
        NavigationStack {
            List {
                sideSection(
                    side: .home,
                    teamName: vm.game.homeTeamName,
                    colourHex: vm.game.homeTeamColourHex
                )
                sideSection(
                    side: .away,
                    teamName: vm.game.awayTeamName,
                    colourHex: vm.game.awayTeamColourHex
                )
            }
            .navigationTitle("Pre-Game Lineup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Side section

    @ViewBuilder
    private func sideSection(
        side: EventTeamSide,
        teamName: String,
        colourHex: String
    ) -> some View {
        let starters  = (side == .home ? vm.homeActivePlayers : vm.awayActivePlayers)
        let bench     = vm.benchPlayers(side: side)
        let teamColor = Color(hex: colourHex)

        Section {
            // Current starters with match-day number stepper
            ForEach(starters) { stat in
                starterRow(stat: stat, teamColor: teamColor, side: side)
            }

            // Bench players available to add
            if !bench.isEmpty {
                benchHeader
                ForEach(bench, id: \.id) { player in
                    benchRow(player: player, teamColor: teamColor, side: side)
                }
            }
        } header: {
            HStack {
                Text(teamName)
                Spacer()
                Text("\(starters.count) starting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Starter row

    @ViewBuilder
    private func starterRow(stat: PlayerGameStat, teamColor: Color, side: EventTeamSide) -> some View {
        HStack(spacing: 10) {
            // Number + name + position
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("#\(stat.playerJerseyNumber)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(teamColor)
                    Text(stat.playerName)
                        .font(.body)
                    if let pos = stat.playerPosition {
                        Text(pos.abbreviation)
                            .font(.caption2.bold())
                            .foregroundStyle(teamColor.opacity(0.7))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(teamColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            Spacer()

            // Match-day number stepper
            Stepper(
                value: Binding(
                    get: { stat.playerJerseyNumber },
                    set: { vm.updateMatchDayNumber(for: stat, to: $0) }
                ),
                in: 1...99
            ) {
                Text("#\(stat.playerJerseyNumber)")
                    .font(.subheadline.monospacedDigit().bold())
                    .frame(minWidth: 32, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                vm.removeFromLineup(stat)
            } label: {
                Label("Remove", systemImage: "person.badge.minus")
            }
        }
    }

    // MARK: - Bench

    private var benchHeader: some View {
        HStack {
            Image(systemName: "person.badge.plus")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tap a bench player to add to the lineup")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private func benchRow(player: Player, teamColor: Color, side: EventTeamSide) -> some View {
        Button {
            vm.addToLineup(player: player, matchDayNumber: player.jerseyNumber, side: side)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)

                Text("#\(player.jerseyNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)

                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                        .foregroundStyle(.primary)
                    if let pos = player.position {
                        Text(pos.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
