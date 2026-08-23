import SwiftUI

/// Glassmorphic empty-state shown in the iPad detail column until a chat,
/// profile or settings destination is selected.
struct ChatDetailPlaceholderView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            VStack(spacing: 14) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.tint)

                Text("Select a chat to start messaging")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Your conversations will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 24, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ChatDetailPlaceholderView()
}
