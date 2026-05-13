import SwiftUI

/// Minimal sheet to create a team with auto-generated numbered players.
/// Designed for quickly setting up an unknown opponent before a game.
struct QuickNumberedTeamSheet: View {
    var onSave: (String, String, String, TeamFormat) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "Opponent"
    @State private var shortName: String = "OPP"
    @State private var selectedColour: Color = .gray
    @State private var selectedFormat: TeamFormat = .fifteens

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shortName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Creates a team with players numbered #1–\(selectedFormat.maxActivePlayers). You can fill in player names during or after the game.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Team Details") {
                    TextField("Team Name", text: $name)
                        .autocorrectionDisabled()

                    HStack {
                        TextField("Short Name (max 4)", text: $shortName)
                            .autocorrectionDisabled()
                            .autocapitalization(.allCharacters)
                            .onChange(of: shortName) { _, v in
                                if v.count > 4 { shortName = String(v.prefix(4)) }
                            }
                        Spacer()
                        Text("\(shortName.count)/4")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Format", selection: $selectedFormat) {
                        ForEach(TeamFormat.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }

                    ColorPicker("Team Colour", selection: $selectedColour)
                }

                Section {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Will generate \(selectedFormat.maxActivePlayers) numbered players")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Quick Numbered Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            shortName.trimmingCharacters(in: .whitespaces).uppercased(),
                            selectedColour.toHex(),
                            selectedFormat
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
