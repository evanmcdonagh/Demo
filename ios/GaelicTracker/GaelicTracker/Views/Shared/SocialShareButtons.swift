import SwiftUI

/// Horizontal row of share buttons for each available social platform.
/// Only shows a platform button if the corresponding app is installed on the device
/// (system share is always visible). Designed to be embedded in a List section.
struct SocialShareButtons: View {
    let game: Game

    /// Tracks which platform the user tapped — used to show a brief "Saved to Photos"
    /// confirmation when sharing to X.
    @State private var showPhotosSavedToast = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Share Result")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(SocialPlatform.allCases) { platform in
                    if platform.isAvailable {
                        platformButton(platform)
                    }
                }
            }

            if showPhotosSavedToast {
                Label("Card saved to Photos — attach it in X!", systemImage: "photo.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: showPhotosSavedToast)
    }

    @ViewBuilder
    private func platformButton(_ platform: SocialPlatform) -> some View {
        Button {
            SocialShareManager.share(game, via: platform)
            if platform == .twitter {
                showPhotosSavedToast = true
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    showPhotosSavedToast = false
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .foregroundStyle(platform.tintColor)
                Text(platform.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
