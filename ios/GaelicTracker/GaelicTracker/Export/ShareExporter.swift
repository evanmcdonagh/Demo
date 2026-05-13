import SwiftUI
import UIKit

@MainActor
enum ShareExporter {
    /// Renders a GameShareCard to a UIImage and presents the share sheet.
    static func shareGame(_ game: Game) {
        let card = GameShareCard(game: game)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0

        guard let uiImage = renderer.uiImage else { return }

        let activityVC = UIActivityViewController(
            activityItems: [uiImage],
            applicationActivities: nil
        )

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(
                x: root.view.bounds.midX,
                y: root.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        root.present(activityVC, animated: true)
    }
}
