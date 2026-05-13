import SwiftUI

struct EventLogView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScoreLegendView(scopeAll: true)
                        .listRowInsets(.init())
                        .listRowBackground(Color.clear)
                }

                ForEach(game.sortedEvents.reversed()) { event in
                    HStack(spacing: 10) {
                        Text(event.minuteDisplay)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        eventTypeIcon(event)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.eventType.displayName)
                                .font(.subheadline)
                            if let name = event.playerName {
                                Text("#\(event.playerJerseyNumber ?? 0) \(name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(event.teamSide == .home ? game.homeTeamShortName : game.awayTeamShortName)
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: event.teamSide == .home ? game.homeTeamColourHex : game.awayTeamColourHex))
                    }
                }
            }
            .navigationTitle("Event Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func eventTypeIcon(_ event: GameEvent) -> some View {
        Image(systemName: event.eventType.iconName)
            .foregroundStyle(event.eventType.swiftUIColor)
            .frame(width: 18)
    }
}
