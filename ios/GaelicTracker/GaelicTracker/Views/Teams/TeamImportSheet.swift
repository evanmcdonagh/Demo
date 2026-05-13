import SwiftUI
import UniformTypeIdentifiers

struct TeamImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let parsedTeam: ParsedTeam
    var onConfirm: (ParsedTeam) -> Void

    var body: some View {
        NavigationStack {
            List {
                // Team metadata
                Section("Team") {
                    LabeledContent("Name", value: parsedTeam.name)
                    LabeledContent("Short Name", value: parsedTeam.shortName)
                    LabeledContent("Colour", value: parsedTeam.colourHex)
                    LabeledContent("Format", value: parsedTeam.format.displayName)
                }

                // Players
                Section("\(parsedTeam.players.count) Players") {
                    ForEach(parsedTeam.players, id: \.jerseyNumber) { player in
                        HStack {
                            Text("#\(player.jerseyNumber)")
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 32, alignment: .trailing)
                            Text(player.name)
                        }
                    }
                }

                // Warnings
                if !parsedTeam.warnings.isEmpty {
                    Section {
                        ForEach(parsedTeam.warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Label("\(parsedTeam.warnings.count) Warning(s)", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .navigationTitle("Import Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onConfirm(parsedTeam)
                        dismiss()
                    }
                }
            }
        }
    }
}
