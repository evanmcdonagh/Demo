import SwiftUI

struct PlayerFormView: View {
    let team: Team
    var editingPlayer: Player?
    var onSave: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var jerseyNumberText: String = ""
    @State private var jerseyError: String?

    private var jerseyNumber: Int? { Int(jerseyNumberText) }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        jerseyNumber != nil &&
        jerseyError == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Details") {
                    TextField("Full Name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Jersey Number", text: $jerseyNumberText)
                        .keyboardType(.numberPad)
                        .onChange(of: jerseyNumberText) { _, newValue in
                            validateJerseyNumber(newValue)
                        }

                    if let error = jerseyError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                        guard let num = jerseyNumber else { return }
                        onSave(name.trimmingCharacters(in: .whitespaces), num)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let player = editingPlayer {
                    name = player.name
                    jerseyNumberText = "\(player.jerseyNumber)"
                }
            }
        }
    }

    private func validateJerseyNumber(_ text: String) {
        guard let num = Int(text) else {
            jerseyError = text.isEmpty ? nil : "Enter a valid number"
            return
        }
        if num < 1 || num > 99 {
            jerseyError = "Jersey number must be 1–99"
        } else {
            // Check uniqueness within team
            let taken = team.players.contains {
                $0.jerseyNumber == num && $0.id != editingPlayer?.id
            }
            jerseyError = taken ? "Jersey #\(num) is already taken" : nil
        }
    }
}
