import SwiftUI

/// Top-floating banner shown over the whole app when a message arrives in a
/// chat the user is not currently reading. Tap to jump to that chat.
struct InAppNotificationView: View {
    private let center = InAppNotificationCenter.shared
    let onTap: (InAppNotificationCenter.Banner) -> Void

    var body: some View {
        VStack {
            if let banner = center.current {
                Button {
                    onTap(banner)
                } label: {
                    HStack(spacing: 10) {
                        AvatarView(title: banner.title, seed: banner.chatID, size: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(banner.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(banner.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.footnote)
                            .foregroundStyle(.tint)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityLabel("New message from \(banner.title)")
            }
            Spacer(minLength: 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: center.current)
    }
}
