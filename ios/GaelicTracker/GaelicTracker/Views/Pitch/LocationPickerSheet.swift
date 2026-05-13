import SwiftUI

struct LocationPickerSheet: View {
    let eventType: EventType
    let playerName: String
    let homeColourHex: String
    let awayColourHex: String
    var existingMarkers: [GameEvent] = []
    @Binding var isPresented: Bool
    var onConfirm: (CGPoint) -> Void

    @State private var selectedLocation: CGPoint?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Tap the pitch to mark the location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)

                PitchView(
                    selectedLocation: $selectedLocation,
                    existingMarkers: existingMarkers,
                    homeColourHex: homeColourHex,
                    awayColourHex: awayColourHex
                )
                .padding()

                if !existingMarkers.isEmpty {
                    ScoreLegendView(scopeAll: false)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    guard let loc = selectedLocation else { return }
                    onConfirm(loc)
                    isPresented = false
                } label: {
                    Label("Confirm Location", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedLocation == nil)
                .padding()
            }
            .navigationTitle("\(playerName) — \(eventType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
