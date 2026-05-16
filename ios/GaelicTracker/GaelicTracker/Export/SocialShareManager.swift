import SwiftUI
import UIKit
import Photos

// MARK: - Platform

enum SocialPlatform: CaseIterable, Identifiable {
    case twitter
    case instagram
    case system

    var id: Self { self }

    var displayName: String {
        switch self {
        case .twitter:   return "X (Twitter)"
        case .instagram: return "Instagram Story"
        case .system:    return "More…"
        }
    }

    var iconName: String {
        switch self {
        case .twitter:   return "x.circle.fill"
        case .instagram: return "camera.circle.fill"
        case .system:    return "square.and.arrow.up"
        }
    }

    var tintColor: Color {
        switch self {
        case .twitter:   return Color(red: 0, green: 0, blue: 0)
        case .instagram: return Color(red: 0.91, green: 0.12, blue: 0.39)
        case .system:    return .accentColor
        }
    }

    /// URL scheme used to detect whether the app is installed.
    var urlScheme: String? {
        switch self {
        case .twitter:   return "twitter://"
        case .instagram: return "instagram-stories://"
        case .system:    return nil
        }
    }

    /// Must be called on the main actor because `UIApplication.shared` is main-actor-isolated.
    @MainActor
    var isAvailable: Bool {
        guard let scheme = urlScheme,
              let url = URL(string: scheme) else { return true }   // system is always available
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Manager

@MainActor
enum SocialShareManager {

    // MARK: - Entry point

    static func share(_ game: Game, via platform: SocialPlatform) {
        guard let image = renderCard(for: game) else { return }

        switch platform {
        case .twitter:   shareToTwitter(game: game, image: image)
        case .instagram: shareToInstagramStories(image: image, game: game)
        case .system:    shareViaSystem(game: game, image: image)
        }
    }

    // MARK: - Twitter / X

    /// Saves the card to Photos, then opens the X app (or web) with a pre-filled tweet.
    private static func shareToTwitter(game: Game, image: UIImage) {
        // 1. Save image to camera roll so the user can attach it in the X compose sheet
        saveImageToPhotos(image)

        // 2. Build tweet text
        let text = tweetText(for: game)
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // 3. Try X/Twitter app first (opens compose), fall back to web intent (pre-filled)
        let appURL = URL(string: "twitter://post")!
        let webURL = URL(string: "https://x.com/intent/tweet?text=\(encoded)")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }

    // MARK: - Instagram Stories

    /// Puts the rendered card on the pasteboard and deep-links into Instagram Stories.
    private static func shareToInstagramStories(image: UIImage, game: Game) {
        guard let imageData = image.pngData() else { return }

        // Instagram reads the background image from the pasteboard using this UTI
        UIPasteboard.general.setData(
            imageData,
            forPasteboardType: "com.instagram.sharedSticker.backgroundImage"
        )

        let bundleId = Bundle.main.bundleIdentifier ?? "com.gaelictracker.app"
        guard let url = URL(string: "instagram-stories://share?source_application=\(bundleId)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - System share sheet

    static func shareViaSystem(game: Game, image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image, tweetText(for: game)],
            applicationActivities: nil
        )

        present(activityVC)
    }

    // MARK: - Helpers

    static func renderCard(for game: Game) -> UIImage? {
        let card = GameShareCard(game: game)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private static func tweetText(for game: Game) -> String {
        let home = game.homeTeamShortName
        let away = game.awayTeamShortName
        let hScore = game.homeScoreDisplay
        let aScore = game.awayScoreDisplay
        return "Full Time ⚽️ \(home) \(hScore) – \(away) \(aScore) #GaelicFootball #GaelicTracker"
    }

    private static func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            DispatchQueue.main.async {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }

    private static func present(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root  = scene.windows.first?.rootViewController else { return }

        if let popover = vc.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(
                x: root.view.bounds.midX, y: root.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }
        root.present(vc, animated: true)
    }
}
