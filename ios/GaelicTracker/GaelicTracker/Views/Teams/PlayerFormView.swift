import SwiftUI

struct PlayerFormView: View {
    let team: Team
    var editingPlayer: Player?
    /// Called with (name, jerseyNumber, position) on save.
    var onSave: (String, Int, GaelicPosition?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var jerseyNumber: Int = 1
    @State private var position: GaelicPosition? = nil

    // MARK: - Derived

    private var jerseyConflict: Bool {
        team.players.contains {
            $0.jerseyNumber == jerseyNumber && $0.id != editingPlayer?.id
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !jerseyConflict
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("Player Details") {
                    TextField("Full Name", text: $name)
                        .autocorrectionDisabled()
                }

                // Jersey number wheel
                Section {
                    Picker("Jersey Number", selection: $jerseyNumber) {
                        ForEach(1...99, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onChange(of: jerseyNumber) { _, num in
                        // Auto-suggest position when adding a new player and position is unset
                        if editingPlayer == nil && position == nil {
                            position = GaelicPosition.suggested(for: num)
                        }
                    }

                    if jerseyConflict {
                        Label("Jersey #\(jerseyNumber) is already taken on this team.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Jersey Number")
                } footer: {
                    Text("Scroll to pick a number 1–99.")
                }

                // Position
                Section("Position") {
                    Picker("Position", selection: $position) {
                        Text("Not set").tag(GaelicPosition?.none)
                        ForEach(GaelicPosition.allCases, id: \.self) { pos in
                            HStack {
                                Text(pos.abbreviation)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, alignment: .leading)
                                Text(pos.displayName)
                            }
                            .tag(Optional(pos))
                        }
                    }
                }
            }
            .navigationTitle(editingPlayer == nil ? "Add Player" : "Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), jerseyNumber, position)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let player = editingPlayer {
                    name = player.name
                    jerseyNumber = player.jerseyNumber
                    position = player.position
                } else {
                    // Default to #1 suggestion when adding fresh
                    position = GaelicPosition.suggested(for: jerseyNumber)
                }
            }
        }
    }
}
