import SwiftUI
import UIKit

struct AvatarView: View {
    var title: String
    var seed: String
    var symbol: String? = nil
    var size: CGFloat = 50
    var isOnline: Bool = false
    var fileName: String? = nil

    @State private var loadedImage: UIImage?

    private var initials: String {
        title.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: AppTheme.avatarColors(for: seed),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(.white)
                    } else {
                        Text(initials)
                            .font(.system(size: size * 0.38, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            if isOnline {
                Circle()
                    .fill(.green)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(
                        Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2)
                    )
            }
        }
        .task(id: fileName) {
            guard let fileName else {
                loadedImage = nil
                return
            }
            loadedImage = ImageCache.shared.image(for: fileName)
        }
        .accessibilityLabel(Text(title))
    }
}

struct UnreadBadge: View {
    let count: Int
    var muted: Bool = false

    var body: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(muted ? AnyShapeStyle(Color(uiColor: .systemGray3)) : AnyShapeStyle(.tint))
            )
            .accessibilityLabel("\(count) unread messages")
    }
}

struct StoredImageView: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task {
            image = ImageCache.shared.image(for: fileName)
        }
    }
}

struct GlassActionButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 52, height: 52)
                    .background(.tint.opacity(0.15), in: Circle())
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
