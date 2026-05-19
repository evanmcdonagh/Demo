import SwiftUI

struct GameSummaryView: View {
    let game: Game
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            // Score header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        HStack(spacing: 24) {
                            teamColumn(
                                crestData: game.homeTeamCrestData,
                                shortName: game.homeTeamShortName,
                                name: game.homeTeamName,
                                colourHex: game.homeTeamColourHex,
                                goals: game.homeGoals,
                                points: game.homePoints,
                                twoPointers: game.homeTwoPointers,
                                alignment: .center
                            )
                            Text("–")
                                .font(.title.bold())
                                .foregroundStyle(.secondary)
                            teamColumn(
                                crestData: game.awayTeamCrestData,
                                shortName: game.awayTeamShortName,
                                name: game.awayTeamName,
                                colourHex: game.awayTeamColourHex,
                                goals: game.awayGoals,
                                points: game.awayPoints,
                                twoPointers: game.awayTwoPointers,
                                alignment: .center
                            )
                        }
                        Text(game.status.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !game.venue.isEmpty {
                            Text(game.venue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // Share buttons
            if game.status == .fullTime {
                Section {
                    SocialShareButtons(game: game)
                }
            }

            // Player stats per team
            statsSection(side: .home, colourHex: game.homeTeamColourHex, teamName: game.homeTeamName)
            statsSection(side: .away, colourHex: game.awayTeamColourHex, teamName: game.awayTeamName)

            // Substitutions
            if !game.substitutions.isEmpty {
                Section("Substitutions") {
                    ForEach(game.substitutions.sorted { $0.clockSeconds < $1.clockSeconds }) { sub in
                        HStack {
                            Text(sub.clockSeconds.minuteString)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 1) {
                                Label("#\(sub.playerOnJerseyNumber) \(sub.playerOnName)", systemImage: "arrow.down.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Label("#\(sub.playerOffJerseyNumber) \(sub.playerOffName)", systemImage: "arrow.up.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                            Text(sub.teamSide == .home ? game.homeTeamShortName : game.awayTeamShortName)
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: sub.teamSide == .home ? game.homeTeamColourHex : game.awayTeamColourHex))
                        }
                    }
                }
            }

            // Pitch heatmap
            let locatedEvents = game.sortedEvents.filter { $0.pitchX != nil }
            if !locatedEvents.isEmpty {
                Section("Scoring & Foul Locations") {
                    PitchView(
                        selectedLocation: .constant(nil),
                        existingMarkers: locatedEvents,
                        homeColourHex: game.homeTeamColourHex,
                        awayColourHex: game.awayTeamColourHex,
                        isReadOnly: true
                    )
                    .listRowInsets(.init())
                    ScoreLegendView(scopeAll: false)
                        .listRowInsets(.init())
                        .listRowBackground(Color.clear)
                }
            }

            // Event timeline
            Section("Event Timeline") {
                ScoreLegendView(scopeAll: true)
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                ForEach(game.sortedEvents) { event in
                    eventRow(event)
                }
                .onDelete { indexSet in
                    let sorted = game.sortedEvents
                    for i in indexSet {
                        deleteEvent(sorted[i])
                    }
                }
            }
        }
        .navigationTitle("\(game.homeTeamShortName) v \(game.awayTeamShortName)")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func teamColumn(
        crestData: Data?, shortName: String, name: String,
        colourHex: String, goals: Int, points: Int, twoPointers: Int = 0,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            CrestOrInitialsView(crestData: crestData, shortName: shortName, colourHex: colourHex, size: 40)
            Text(shortName).font(.caption.bold())
            ScoreFormatView(goals: goals, points: points, twoPointers: twoPointers)
        }
    }

    private func statsSection(side: EventTeamSide, colourHex: String, teamName: String) -> some View {
        let stats = game.playerStats
            .filter { $0.teamSide == side }
            .sorted { $0.totalPointValue > $1.totalPointValue }

        return Section(teamName) {
            ForEach(stats) { stat in
                HStack {
                    Text("#\(stat.playerJerseyNumber)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color(hex: colourHex))
                        .frame(width: 28, alignment: .trailing)
                    Text(stat.playerName)
                        .font(.subheadline)
                    Spacer()
                    if stat.totalPointValue > 0 {
                        Text(stat.scoreDisplay)
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(Color(hex: colourHex))
                    }
                    cardIndicators(stat: stat)
                    if !stat.isCurrentlyOnField && stat.substitutedOffAtSecond != nil {
                        Image(systemName: "arrow.up.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cardIndicators(stat: PlayerGameStat) -> some View {
        HStack(spacing: 2) {
            if stat.yellowCards > 0 { CardBadgeView(status: .yellow) }
            if stat.blackCards > 0 { CardBadgeView(status: .black) }
            if stat.redCards > 0 { CardBadgeView(status: .red) }
        }
    }

    @ViewBuilder
    private func eventRow(_ event: GameEvent) -> some View {
        HStack(spacing: 8) {
            Text(event.minuteDisplay)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)

            eventIcon(event)

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

    @ViewBuilder
    private func eventIcon(_ event: GameEvent) -> some View {
        Image(systemName: event.eventType.iconName)
            .foregroundStyle(event.eventType.swiftUIColor)
            .frame(width: 20)
    }

    // MARK: - Post-match event deletion

    private func deleteEvent(_ event: GameEvent) {
        // Reverse stat contribution
        if let playerID = event.playerID,
           let stat = game.playerStats.first(where: {
               $0.playerID == playerID && $0.teamSide == event.teamSide
           }) {
            switch event.eventType {
            case .goal:         stat.goals          = max(0, stat.goals - 1)
            case .point:        stat.points         = max(0, stat.points - 1)
            case .twoPointer:   stat.twoPointers    = max(0, stat.twoPointers - 1)
            case .freeAwarded:  stat.foulsCommitted = max(0, stat.foulsCommitted - 1)
            case .freeConceded: stat.freesConceded  = max(0, stat.freesConceded - 1)
            case .kickoutWon:   stat.kickoutsWon    = max(0, stat.kickoutsWon - 1)
            case .yellowCard:   stat.yellowCards    = max(0, stat.yellowCards - 1)
            case .blackCard:    stat.blackCards     = max(0, stat.blackCards - 1)
            case .redCard:      stat.redCards       = max(0, stat.redCards - 1)
            }
        }
        game.events.removeAll { $0.id == event.id }
        context.delete(event)
        try? context.save()
    }
}
