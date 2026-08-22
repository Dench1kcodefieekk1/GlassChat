import SwiftUI

/// 3-column Telegram-style grid of owned gifts and NFT collectibles.
/// Cells render bundled Lottie vector animations via `GiftAnimationView`.
struct GiftsGridView: View {
    let gifts: [GiftItem]
    let onTap: (GiftItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        if gifts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("No gifts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gifts) { gift in
                    GiftCell(kind: gift.kind)
                        .onTapGesture { onTap(gift) }
                }
            }
        }
    }
}

// MARK: - Cell

private struct GiftCell: View {
    let kind: GiftKind

    var body: some View {
        VStack(spacing: 8) {
            GiftAnimationView(filename: kind.lottieFilename)
                .frame(height: 64)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            Text(kind.rarity.tag)
                .font(.system(size: 10, weight: .bold))
                .monospaced()
                .foregroundStyle(kind.rarity == .nft ? AnyShapeStyle(.white) : AnyShapeStyle(.primary.opacity(0.75)))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    kind.rarity == .nft
                        ? AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color(uiColor: .tertiarySystemFill)),
                    in: Capsule()
                )
        }
        .padding(10)
        .frame(height: 118)
        .frame(maxWidth: .infinity)
        .background(cardGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .accessibilityLabel("\(kind.title) \(kind.rarity.tag)")
    }

    private var cardGradient: AnyShapeStyle {
        switch kind {
        case .diamondRing:
            return AnyShapeStyle(LinearGradient(colors: [Color.indigo.opacity(0.35), Color.cyan.opacity(0.25)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .cyberCat:
            return AnyShapeStyle(LinearGradient(colors: [Color.teal.opacity(0.32), Color.mint.opacity(0.2)],
                                                startPoint: .top, endPoint: .bottom))
        case .goldStar:
            return AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.76, blue: 0.2).opacity(0.35), Color.yellow.opacity(0.18)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .rainbowNyanCat:
            return AnyShapeStyle(LinearGradient(colors: [Color.pink.opacity(0.35), Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .viceCream:
            return AnyShapeStyle(LinearGradient(colors: [Color.orange.opacity(0.32), Color.pink.opacity(0.25)],
                                                startPoint: .top, endPoint: .bottom))
        }
    }
}
