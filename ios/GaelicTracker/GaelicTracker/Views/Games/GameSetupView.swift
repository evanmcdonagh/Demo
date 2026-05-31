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

    // Starting lineup
    @State private var selectedHomePlayers: Set<UUID> = []
    @State private var selectedAwayPlayers: Set<UUID> = []

    // MARK: - Derived state

    private var homeIsSet: Bool { homeIsGuest || homeTeam != nil }
    private var awayIsSet: Bool { awayIsGuest || awayTeam != nil }

    private var canProceed: Bool {
        guard homeIsSet && awayIsSet else { return false }
        // Can't have two guest teams in the same game
        if homeIsGuest && awayIsGuest { return false }
        // Can't pick the same real team on both sides
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
            // ── Home ──────────────────────────────────────────────────
            teamSlotView(
                label: "Home",
                icon: "house.fill",
                isGuest: $homeIsGuest,
                selectedTeam: $homeTeam,
                guestName: $homeGuestName,
                excludeTeam: awayTeam
            )

            // ── Swap button ───────────────────────────────────────────
            Button(action: swapSides) {
                Label("Swap Home & Away", systemImage: "arrow.up.arrow.down")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(!(homeIsSet && awayIsSet))

            // ── Away ──────────────────────────────────────────────────
            teamSlotView(
                label: "Away",
                icon: "mappin.circle.fill",
                isGuest: $awayIsGuest,
                selectedTeam: $awayTeam,
                guestName: $awayGuestName,
                excludeTeam: homeTeam
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
        label: String,
        icon: String,
        isGuest: Binding<Bool>,
        selectedTeam: Binding<Team?>,
        guestName: Binding<String>,
        excludeTeam: Team?
    ) -> some View {
        // Toggle row
        Toggle(isOn: isGuest) {
            Label("\(label) — Guest Team", systemImage: icon)
        }
        .onChange(of: isGuest.wrappedValue) { _, on in
            if on { selectedTeam.wrappedValue = nil }
        }

        if isGuest.wrappedValue {
            // Guest name field
            HStack {
                Text("Name")
                    .foregroundStyle(.secondary)
                TextField("e.g. Opponents", text: guestName)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
        } else {
            // Normal team picker
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
            }
        }
    }

    // MARK: - Settings section

    private var settingsSection: some View {
        Section("Venue & Format") {
            TextField("Venue", text: $venue)
                .autocorrectionDisabled()

            Picker("Format", selection: $selectedFormat) {
                ForEach(TeamFormat.allCases, id: \.self) { f in
                    Text(f.displayName).tag(f)
                }
            }

            Stepper("Half Duration: \(halfDuration) min", value: $halfDuration, in: 10...45, step: 5)
        }
    }

    // MARK: - Starting lineup section

    @ViewBuilder
    private var lineupSection: some View {
        if !homeIsGuest {
            Section("Home Starting \(selectedHomePlayers.count)/\(selectedFormat.maxActivePlayers)") {
                ForEach(homeSorted) { player in
                    playerToggle(player: player, selection: $selectedHomePlayers)
                }
            }
        }

        if !awayIsGuest {
            Section("Away Starting \(selectedAwayPlayers.count)/\(selectedFormat.maxActivePlayers)") {
                ForEach(awaySorted) { player in
                    playerToggle(player: player, selection: $selectedAwayPlayers)
                }
            }
        }
    }

    @ViewBuilder
    private func playerToggle(player: Player, selection: Binding<Set<UUID>>) -> some View {
        Toggle(isOn: Binding(
            get: { selection.wrappedValue.contains(player.id) },
            set: { on in
                if on {
                    if selection.wrappedValue.count < selectedFormat.maxActivePlayers {
                        selection.wrappedValue.insert(player.id)
                    }
                } else {
                    selection.wrappedValue.remove(player.id)
                }
            }
        )) {
            Text("#\(player.jerseyNumber) \(player.name)")
        }
    }

    // MARK: - Actions

    private func applyDefaults() {
        if let t = teams.first { homeTeam = t; selectedFormat = t.format }
        if teams.count > 1 { awayTeam = teams[1] }
        preselectStartingPlayers()
    }

    private func swapSides() {
        // Swap guest flags
        let tmpGuest = homeIsGuest
        homeIsGuest = awayIsGuest
        awayIsGuest = tmpGuest
        // Swap guest names
        let tmpName = homeGuestName
        homeGuestName = awayGuestName
        awayGuestName = tmpName
        // Swap real team selections
        let tmpTeam = homeTeam
        homeTeam = awayTeam
        awayTeam = tmpTeam
        // Swap lineup selections
        let tmpPlayers = selectedHomePlayers
        selectedHomePlayers = selectedAwayPlayers
        selectedAwayPlayers = tmpPlayers
    }

    private func preselectStartingPlayers() {
        selectedHomePlayers = Set(homeSorted.prefix(selectedFormat.maxActivePlayers).map(\.id))
        selectedAwayPlayers = Set(awaySorted.prefix(selectedFormat.maxActivePlayers).map(\.id))
    }

    /// Derives a `GuestTeamInfo` from a raw name string entered by the user.
    private func guestInfo(from rawName: String) -> GuestTeamInfo {
        let name = rawName.trimmingCharacters(in: .whitespaces)
        let safeName = name.isEmpty ? "Guest" : name
        let short = String(safeName.filter { !$0.isWhitespace }.prefix(4)).uppercased()
        let safeShort = short.isEmpty ? "GST" : short
        return GuestTeamInfo(name: safeName, shortName: safeShort)
    }

    private func createGame() {
        let homeSource: TeamSource = homeIsGuest
            ? .guest(info: guestInfo(from: homeGuestName))
            : .roster(team: homeTeam!, startingPlayers: homeSorted.filter { selectedHomePlayers.contains($0.id) })

        let awaySource: TeamSource = awayIsGuest
            ? .guest(info: guestInfo(from: awayGuestName))
            : .roster(team: awayTeam!, startingPlayers: awaySorted.filter { selectedAwayPlayers.contains($0.id) })

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
