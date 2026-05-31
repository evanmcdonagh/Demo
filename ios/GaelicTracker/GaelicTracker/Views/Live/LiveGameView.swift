import SwiftUI

struct LiveGameView: View {
    let game: Game
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: LiveGameViewModel?
    @State private var showEventLog = false
    @State private var showSummary = false
    @State private var showPreGameLineup = false

    private var vm: LiveGameViewModel? { viewModel }

    var body: some View {
        Group {
            if let vm {
                liveContent(vm)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = LiveGameViewModel(game: game, context: context)
                    }
            }
        }
        .navigationTitle("\(game.homeTeamShortName) v \(game.awayTeamShortName)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(game.status.isLive)
        .toolbar {
            // Edit lineup (pre-kick-off only)
            ToolbarItem(placement: .navigationBarLeading) {
                if game.status == .notStarted {
                    Button {
                        showPreGameLineup = true
                    } label: {
                        Label("Edit Lineup", systemImage: "person.badge.plus")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showEventLog = true
                    } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    if game.status == .fullTime {
                        Button("Summary") { showSummary = true }
                    }
                }
            }
        }
        .sheet(isPresented: $showPreGameLineup) {
            if let vm { PreGameLineupView(vm: vm) }
        }
        .sheet(isPresented: $showEventLog) {
            if let vm {
                EventLogView(game: vm.game, onDeleteEvent: { vm.deleteEvent($0) })
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm?.syncFromWallClock() }
        }
        .navigationDestination(isPresented: $showSummary) {
            GameSummaryView(game: game)
        }
    }

    @ViewBuilder
    private func liveContent(_ vm: LiveGameViewModel) -> some View {
        VStack(spacing: 0) {
            // Scoreboard
            ScoreboardView(game: vm.game, elapsedSeconds: vm.elapsedSeconds)

            Divider()

            // Clock controls
            ClockView(viewModel: vm)

            Divider()

            // Side-by-side roster
            HStack(spacing: 0) {
                // Home
                VStack(spacing: 0) {
                    Text(vm.game.homeTeamShortName)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: vm.game.homeTeamColourHex))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color(hex: vm.game.homeTeamColourHex).opacity(0.1))

                    ActiveRosterView(
                        players: vm.homeActivePlayers,
                        teamColour: Color(hex: vm.game.homeTeamColourHex),
                        sinBinExpiry: vm.sinBinExpiry,
                        elapsedSeconds: vm.elapsedSeconds,
                        isGameLive: vm.game.status.isLive,
                        onBeginScoring: { type, stat in
                            vm.beginScoringEvent(type: type, teamSide: .home, player: stat)
                        },
                        onInstantEvent: { type, stat in
                            vm.recordInstantEvent(type, for: stat)
                        },
                        onCard: { type, stat in
                            vm.recordCard(type, for: stat)
                        },
                        onSubstitution: { stat in
                            vm.openSubstitutionSheet(for: .home)
                        }
                    )
                }

                Divider()

                // Away
                VStack(spacing: 0) {
                    Text(vm.game.awayTeamShortName)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: vm.game.awayTeamColourHex))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color(hex: vm.game.awayTeamColourHex).opacity(0.1))

                    ActiveRosterView(
                        players: vm.awayActivePlayers,
                        teamColour: Color(hex: vm.game.awayTeamColourHex),
                        sinBinExpiry: vm.sinBinExpiry,
                        elapsedSeconds: vm.elapsedSeconds,
                        isGameLive: vm.game.status.isLive,
                        onBeginScoring: { type, stat in
                            vm.beginScoringEvent(type: type, teamSide: .away, player: stat)
                        },
                        onInstantEvent: { type, stat in
                            vm.recordInstantEvent(type, for: stat)
                        },
                        onCard: { type, stat in
                            vm.recordCard(type, for: stat)
                        },
                        onSubstitution: { stat in
                            vm.openSubstitutionSheet(for: .away)
                        }
                    )
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showLocationPicker },
            set: { if !$0 { vm.cancelPendingEvent() } }
        )) {
            if let type = vm.pendingEventType {
                LocationPickerSheet(
                    eventType: type,
                    playerName: vm.pendingPlayerStat?.playerName ?? "",
                    homeColourHex: vm.game.homeTeamColourHex,
                    awayColourHex: vm.game.awayTeamColourHex,
                    existingMarkers: vm.game.events.filter { $0.needsPitchLocation },
                    isPresented: Binding(
                        get: { vm.showLocationPicker },
                        set: { vm.showLocationPicker = $0 }
                    ),
                    onConfirm: { loc in
                        vm.confirmLocation(pitchX: loc.x, pitchY: loc.y)
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showSubstitutionSheet },
            set: { vm.showSubstitutionSheet = $0 }
        )) {
            SubstitutionSheetView(viewModel: vm, teamSide: vm.substitutionTeamSide)
        }
    }
}

extension GameEvent {
    var needsPitchLocation: Bool { pitchX != nil && pitchY != nil }
}
