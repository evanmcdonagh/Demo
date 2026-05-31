import SwiftUI
import SwiftData

struct GameSetupView: View {
    let viewModel: GameViewModel
    var onGameCreated: (Game) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    // Home side
    @State private var homeTeam: Team?
    @State private var homeIsGuest = false
    @State private var homeGuestName = "Guest"

    // Away side
    @State private var awayTeam: Team?
    @State private var awayIsGuest = false
    @State private var awayGuestName = "Guest"

    // Game settings
    @State private var venue = ""
    @State private var selectedFormat: TeamFormat = .fifteens
    @State private var halfDuration = 30

    // Lineup: player ID → match-day jersey number.
    // Presence in the dictionary means the player is selected for this game.
    @State private var homeMatchDayNumbers: [UUID: Int] = [:]
    @State private var awayMatchDayNumbers: [UUID: Int] = [:]

    // MARK: - Derived state

    private var homeIsSet: Bool { homeIsGuest || homeTeam != nil }
    private var awayIsSet: Bool { awayIsGuest || awayTeam != nil }

    private var canProceed: Bool {
        guard homeIsSet && awayIsSet else { return false }
        if homeIsGuest && awayIsGuest { return false }
        if let h = homeTeam, let a = awayTeam, h.id == a.id { return false }
        return true
    }

    private var homeSorted: [Player] { homeTeam?.sortedPlayers ?? [] }
    private var awaySorted: [Player] { awayTeam?.sortedPlayers ?? [] }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                teamSection
                settingsSection
                if canProceed { lineupSection }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game", action: createGame)
                        .disabled(!canProceed)
                }
            }
            .onAppear { applyDefaults() }
        }
    }

    // MARK: - Team section

    private var teamSection: some View {
        Section {
            teamSlotView(
                label: "Home", icon: "house.fill",
                isGuest: $homeIsGuest, selectedTeam: $homeTeam,
                guestName: $homeGuestName, excludeTeam: awayTeam
            )

            Button(action: swapSides) {
                Label("Swap Home & Away", systemImage: "arrow.up.arrow.down")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(!(homeIsSet && awayIsSet))

            teamSlotView(
                label: "Away", icon: "mappin.circle.fill",
                isGuest: $awayIsGuest, selectedTeam: $awayTeam,
                guestName: $awayGuestName, excludeTeam: homeTeam
            )
        } header: {
            Text("Teams")
        } footer: {
            if homeIsGuest || awayIsGuest {
                Text("Guest team players are automatically numbered #1 through the selected format count.")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func teamSlotView(
        label: String, icon: String,
        isGuest: Binding<Bool>, selectedTeam: Binding<Team?>,
        guestName: Binding<String>, excludeTeam: Team?
    ) -> some View {
        Toggle(isOn: isGuest) {
            Label("\(label) — Guest Team", systemImage: icon)
        }
        .onChange(of: isGuest.wrappedValue) { _, on in
            if on { selectedTeam.wrappedValue = nil }
        }

        if isGuest.wrappedValue {
            HStack {
                Text("Name").foregroundStyle(.secondary)
                TextField("e.g. Opponents", text: guestName)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
        } else {
            Picker(label, selection: selectedTeam) {
                Text("Select team…").tag(Optional<Team>.none)
                ForEach(teams.filter { $0.id != excludeTeam?.id }) { team in
                    HStack {
                        CrestOrInitialsView(
                            crestData: team.crestImageData,
                            shortName: team.shortName,
                            colourHex: team.colourHex,
                            size: 20
                        )
                        Text(team.name)
                    }
                    .tag(Optional(team))
                }
            }
            .onChange(of: selectedTeam.wrappedValue) { _, t in
                if let t, label == "Home" { selectedFormat = t.format }
                preselectStartingPlayers()
            }
        }
    }

    // MARK: - Settings section

    private var settingsSection: some View {
        Section("Venue & Format") {
            TextField("Venue", text: $venue)
                .autocorrectionDisabled()
            Picker("Format", selection: $selectedFormat) {
                ForEach(TeamFormat.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .onChange(of: selectedFormat) { _, _ in preselectStartingPlayers() }
            Stepper("Half Duration: \(halfDuration) min", value: $halfDuration, in: 10...45, step: 5)
        }
    }

    // MARK: - Lineup section

    @ViewBuilder
    private var lineupSection: some View {
        if !homeIsGuest {
            Section {
                ForEach(homeSorted) { player in
                    playerRows(player: player,
                               matchDayNumbers: $homeMatchDayNumbers,
                               maxCount: selectedFormat.maxActivePlayers)
                }
            } header: {
                Text("Home Starting (\(homeMatchDayNumbers.count)/\(selectedFormat.maxActivePlayers))")
            } footer: {
                Text("Squad # is shown in grey. Tap + / – to set the match-day # the player will wear in this game.")
                    .font(.caption)
            }
        }

        if !awayIsGuest {
            Section {
                ForEach(awaySorted) { player in
                    playerRows(player: player,
                               matchDayNumbers: $awayMatchDayNumbers,
                               maxCount: selectedFormat.maxActivePlayers)
                }
            } header: {
                Text("Away Starting (\(awayMatchDayNumbers.count)/\(selectedFormat.maxActivePlayers))")
            } footer: {
                Text("Squad # is shown in grey. Tap + / – to set the match-day # the player will wear in this game.")
                    .font(.caption)
            }
        }
    }

    /// Renders up to two rows per player: a selection toggle, and (when selected) a match-day number stepper.
    @ViewBuilder
    private func playerRows(
        player: Player,
        matchDayNumbers: Binding<[UUID: Int]>,
        maxCount: Int
    ) -> some View {
        let isSelected = matchDayNumbers.wrappedValue[player.id] != nil
        let matchDayNumber = matchDayNumbers.wrappedValue[player.id] ?? player.jerseyNumber

        // ── Selection toggle ─────────────────────────────────────────────
        Toggle(isOn: Binding(
            get: { isSelected },
            set: { on in
                if on {
                    guard matchDayNumbers.wrappedValue.count < maxCount else { return }
                    matchDayNumbers.wrappedValue[player.id] = player.jerseyNumber
                } else {
                    matchDayNumbers.wrappedValue.removeValue(forKey: player.id)
                }
            }
        )) {
            HStack(spacing: 8) {
                Text("#\(player.jerseyNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                    if let pos = player.position {
                        Text(pos.abbreviation)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        // ── Match-day number stepper (only when selected) ────────────────
        if isSelected {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Match-day jersey #")
                        .font(.subheadline)
                    if matchDayNumber != player.jerseyNumber {
                        Text("Squad # is \(player.jerseyNumber)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Stepper(
                    value: Binding(
                        get: { matchDayNumber },
                        set: { matchDayNumbers.wrappedValue[player.id] = $0 }
                    ),
                    in: 1...99
                ) {
                    Text("\(matchDayNumber)")
                        .font(.title3.monospacedDigit().bold())
                        .frame(minWidth: 36, alignment: .trailing)
                }
            }
            .padding(.leading, 44)
        }
    }

    // MARK: - Actions

    private func applyDefaults() {
        if let t = teams.first { homeTeam = t; selectedFormat = t.format }
        if teams.count > 1 { awayTeam = teams[1] }
        preselectStartingPlayers()
    }

    private func swapSides() {
        swap(&homeIsGuest, &awayIsGuest)
        swap(&homeGuestName, &awayGuestName)
        swap(&homeTeam, &awayTeam)
        swap(&homeMatchDayNumbers, &awayMatchDayNumbers)
    }

    private func preselectStartingPlayers() {
        homeMatchDayNumbers = Dictionary(
            uniqueKeysWithValues: homeSorted
                .prefix(selectedFormat.maxActivePlayers)
                .map { ($0.id, $0.jerseyNumber) }
        )
        awayMatchDayNumbers = Dictionary(
            uniqueKeysWithValues: awaySorted
                .prefix(selectedFormat.maxActivePlayers)
                .map { ($0.id, $0.jerseyNumber) }
        )
    }

    private func guestInfo(from rawName: String) -> GuestTeamInfo {
        let name = rawName.trimmingCharacters(in: .whitespaces)
        let safeName = name.isEmpty ? "Guest" : name
        let short = String(safeName.filter { !$0.isWhitespace }.prefix(4)).uppercased()
        return GuestTeamInfo(name: safeName, shortName: short.isEmpty ? "GST" : short)
    }

    private func createGame() {
        let homeSource: TeamSource = homeIsGuest
            ? .guest(info: guestInfo(from: homeGuestName))
            : .roster(
                team: homeTeam!,
                startingPlayers: homeSorted.compactMap { player in
                    guard let num = homeMatchDayNumbers[player.id] else { return nil }
                    return (player, num)
                }
              )

        let awaySource: TeamSource = awayIsGuest
            ? .guest(info: guestInfo(from: awayGuestName))
            : .roster(
                team: awayTeam!,
                startingPlayers: awaySorted.compactMap { player in
                    guard let num = awayMatchDayNumbers[player.id] else { return nil }
                    return (player, num)
                }
              )

        let game = viewModel.createGame(
            home: homeSource,
            away: awaySource,
            venue: venue.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            halfDurationMinutes: halfDuration
        )
        onGameCreated(game)
        dismiss()
    }
}
