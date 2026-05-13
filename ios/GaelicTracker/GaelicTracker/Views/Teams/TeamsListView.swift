import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TeamsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]

    @State private var showCreateTeam = false
    @State private var showQuickTeam = false
    @State private var showFileImporter = false
    @State private var parsedTeam: ParsedTeam? = nil
    @State private var importError: String? = nil
    @State private var showImportError = false
    private var viewModel: TeamViewModel { TeamViewModel(context: context) }

    var body: some View {
        NavigationStack {
            Group {
                if teams.isEmpty {
                    EmptyStateView(
                        systemImage: "shield.lefthalf.filled",
                        title: "No Teams",
                        message: "Create your first team to get started.",
                        actionTitle: "Create Team",
                        action: { showCreateTeam = true }
                    )
                } else {
                    List {
                        ForEach(teams) { team in
                            NavigationLink {
                                TeamDetailView(team: team, viewModel: viewModel)
                            } label: {
                                HStack(spacing: 12) {
                                    CrestOrInitialsView(
                                        crestData: team.crestImageData,
                                        shortName: team.shortName,
                                        colourHex: team.colourHex,
                                        size: 40
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(team.name)
                                            .font(.headline)
                                        Text("\(team.format.displayName) · \(team.players.count) players")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTeam(team)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showCreateTeam = true
                        } label: {
                            Label("New Team", systemImage: "shield.lefthalf.filled")
                        }
                        Button {
                            showQuickTeam = true
                        } label: {
                            Label("Quick Numbered Team", systemImage: "number.circle")
                        }
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Import from CSV", systemImage: "doc.text")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                TeamFormView { name, shortName, colour, format, crest in
                    let team = viewModel.createTeam(name: name, shortName: shortName, colourHex: colour, format: format)
                    if let crest {
                        team.crestImageData = crest
                        try? context.save()
                    }
                }
            }
            .sheet(isPresented: $showQuickTeam) {
                QuickNumberedTeamSheet { name, shortName, colour, format in
                    let team = viewModel.createTeam(name: name, shortName: shortName, colourHex: colour, format: format)
                    viewModel.generateNumberedSquad(for: team)
                }
            }
            .sheet(item: $parsedTeam) { team in
                TeamImportSheet(parsedTeam: team) { confirmed in
                    viewModel.importTeam(from: confirmed)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText]
            ) { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else {
                        importError = "Permission denied for that file."
                        showImportError = true
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    do {
                        let csv = try String(contentsOf: url, encoding: .utf8)
                        let parsed = try CSVTeamParser.parse(csv)
                        parsedTeam = parsed
                    } catch {
                        importError = error.localizedDescription
                        showImportError = true
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Unknown error.")
            }
        }
    }
}
