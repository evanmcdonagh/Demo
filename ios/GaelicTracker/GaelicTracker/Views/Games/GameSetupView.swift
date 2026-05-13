import SwiftUI
import SwiftData

struct GameSetupView: View {
    let viewModel: GameViewModel
    var onGameCreated: (Game) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var homeTeam: Team?
    @State private var awayTeam: Team?
    @State private var venue: String = ""
    @State private var selectedFormat: TeamFormat = .fifteens
    @State private var halfDuration: Int = 30
    @State private var showStartingLineup = false

    // Starting lineup selections
    @State private var selectedHomePlayers: Set<UUID> = []
    @State private var selectedAwayPlayers: Set<UUID> = []

    private var canProceed: Bool {
        homeTeam != nil && awayTeam != nil && homeTeam?.id != awayTeam?.id
    }

    private var homeSorted: [Player] { homeTeam?.sortedPlayers ?? [] }
    private var awaySorted: [Player] { awayTeam?.sortedPlayers ?? [] }

    var body: some View {
        NavigationStack {
            Form {
                teamPickerSection

                Section("Venue & Format") {
                    TextField("Venue", text: $venue)
                        .autocorrectionDisabled()

                    Picker("Format", selection: $selectedFormat) {
                        ForEach(TeamFormat.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    .onChange(of: homeTeam) { _, t in if let t { selectedFormat = t.format } }

                    Stepper("Half Duration: \(halfDuration) min", value: $halfDuration, in: 10...45, step: 5)
                }

                if canProceed {
                    startingLineupSection
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game") {
                        createGame()
                    }
                    .disabled(!canProceed)
                }
            }
            .onAppear {
                if let t = teams.first { homeTeam = t; selectedFormat = t.format }
                if teams.count > 1 { awayTeam = teams[1] }
            }
        }
    }

    private var teamPickerSection: some View {
        Section("Teams") {
            teamPicker(label: "Home", selection: $homeTeam, exclude: awayTeam)
            teamPicker(label: "Away", selection: $awayTeam, exclude: homeTeam)
        }
    }

    @ViewBuilder
    private func teamPicker(label: String, selection: Binding<Team?>, exclude: Team?) -> some View {
        Picker(label, selection: selection) {
            Text("Select…").tag(Optional<Team>.none)
            ForEach(teams.filter { $0.id != exclude?.id }) { team in
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
    }

    private var startingLineupSection: some View {
        Group {
            Section("Home Starting \(selectedHomePlayers.count)/\(selectedFormat.maxActivePlayers)") {
                ForEach(homeSorted) { player in
                    Toggle(isOn: Binding(
                        get: { selectedHomePlayers.contains(player.id) },
                        set: { on in
                            if on {
                                if selectedHomePlayers.count < selectedFormat.maxActivePlayers {
                                    selectedHomePlayers.insert(player.id)
                                }
                            } else {
                                selectedHomePlayers.remove(player.id)
                            }
                        }
                    )) {
                        Text("#\(player.jerseyNumber) \(player.name)")
                    }
                }
            }

            Section("Away Starting \(selectedAwayPlayers.count)/\(selectedFormat.maxActivePlayers)") {
                ForEach(awaySorted) { player in
                    Toggle(isOn: Binding(
                        get: { selectedAwayPlayers.contains(player.id) },
                        set: { on in
                            if on {
                                if selectedAwayPlayers.count < selectedFormat.maxActivePlayers {
                                    selectedAwayPlayers.insert(player.id)
                                }
                            } else {
                                selectedAwayPlayers.remove(player.id)
                            }
                        }
                    )) {
                        Text("#\(player.jerseyNumber) \(player.name)")
                    }
                }
            }
        }
        .onAppear { preselectStartingPlayers() }
        .onChange(of: homeTeam) { _, _ in preselectStartingPlayers() }
        .onChange(of: awayTeam) { _, _ in preselectStartingPlayers() }
        .onChange(of: selectedFormat) { _, _ in preselectStartingPlayers() }
    }

    private func preselectStartingPlayers() {
        let homeList = homeSorted.prefix(selectedFormat.maxActivePlayers)
        selectedHomePlayers = Set(homeList.map(\.id))
        let awayList = awaySorted.prefix(selectedFormat.maxActivePlayers)
        selectedAwayPlayers = Set(awayList.map(\.id))
    }

    private func createGame() {
        guard let home = homeTeam, let away = awayTeam else { return }
        let homePlayers = homeSorted.filter { selectedHomePlayers.contains($0.id) }
        let awayPlayers = awaySorted.filter { selectedAwayPlayers.contains($0.id) }
        let game = viewModel.createGame(
            homeTeam: home,
            awayTeam: away,
            venue: venue.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            halfDurationMinutes: halfDuration,
            startingHomePlayers: homePlayers,
            startingAwayPlayers: awayPlayers
        )
        onGameCreated(game)
        dismiss()
    }
}
