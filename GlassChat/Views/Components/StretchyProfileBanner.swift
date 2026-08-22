import SwiftUI

/// Telegram-style stretchy profile banner: grows when pulled down, shows the
/// user's custom banner image when set, and falls back to a themed gradient.
struct StretchyProfileBanner: View {
    let user: User
    var height: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            bannerContent
                .frame(width: geo.size.width, height: height + max(0, minY))
                .clipped()
                .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: height)
        .accessibilityLabel("Profile banner")
    }

    @ViewBuilder
    private var bannerContent: some View {
        if let bannerFile = user.bannerFileName {
            StoredImageView(fileName: bannerFile)
        } else {
            LinearGradient(
                colors: AppTheme.avatarColors(for: user.id),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.55)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color(uiColor: .systemBackground).opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    .padding(18)
            )
        }
    }
}
