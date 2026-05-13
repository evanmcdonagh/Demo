import SwiftUI

/// A tap-to-locate pitch view. Stores coordinates normalised to 0.0–1.0.
struct PitchView: View {
    @Binding var selectedLocation: CGPoint?
    var existingMarkers: [GameEvent] = []
    var homeColourHex: String = "#1A73E8"
    var awayColourHex: String = "#E8341A"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Pitch background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.18, green: 0.55, blue: 0.18))

                // Pitch markings
                GaelicPitchShape()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.2)
                    .padding(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))

                // Existing event markers
                ForEach(existingMarkers) { event in
                    if let px = event.pitchX, let py = event.pitchY {
                        markerView(event: event)
                            .position(
                                x: geo.size.width * px,
                                y: geo.size.height * py
                            )
                    }
                }

                // Selected location preview
                if let loc = selectedLocation {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .shadow(radius: 3)
                        .position(
                            x: geo.size.width * loc.x,
                            y: geo.size.height * loc.y
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { tap in
                selectedLocation = CGPoint(
                    x: tap.x / geo.size.width,
                    y: tap.y / geo.size.height
                )
            }
        }
        .aspectRatio(0.55, contentMode: .fit)
    }

    @ViewBuilder
    private func markerView(event: GameEvent) -> some View {
        let color: Color = {
            switch event.eventType {
            case .goal: return Color(hex: event.teamSide == .home ? homeColourHex : awayColourHex)
            case .point: return Color(hex: event.teamSide == .home ? homeColourHex : awayColourHex).opacity(0.7)
            case .freeAwarded: return .orange
            default: return .gray
            }
        }()
        let label: String = {
            switch event.eventType {
            case .goal: return "G"
            case .point: return "P"
            case .freeAwarded: return "F"
            default: return "?"
            }
        }()
        ZStack {
            Circle().fill(color).frame(width: 14, height: 14)
            Text(label).font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
        }
    }
}
