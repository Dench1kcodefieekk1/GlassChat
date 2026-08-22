import SwiftUI

/// Telegram-style bottom sheet for a rare NFT collectible, with market
/// attributes and the full action bar (Transfer / Wear / Sell).
struct NFTGiftDetailView: View {
    let gift: GiftItem
    let ownerName: String
    let isWorn: Bool
    let onToggleVisibility: () -> Void
    let onWear: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var kind: GiftKind { gift.kind }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("\(kind.title) \(kind.serialNumber ?? "")")
                            .font(.headline)
                        Text(kind.modelName ?? "")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.tint.opacity(0.14), in: Capsule())
                            .foregroundStyle(.tint)
                    }
                    .padding(.top, 6)

                    actionBar

                    attributeTable

                    Button {
                        onToggleVisibility()
                    } label: {
                        Text(gift.isHiddenFromProfile
                             ? "Подарок скрыт. Показать >"
                             : "Подарок виден в профиле. Скрыть >")
                            .font(.footnote)
                            .foregroundStyle(.tint)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 18)
            }

            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text("OK")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.tint, in: Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .presentationDetents([.large])
    }

    // MARK: - Header with gradient backdrop

    private var header: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.purple.opacity(0.55), Color.pink.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 210)
            .overlay(alignment: .bottom) {
                ZStack {
                    GiftAnimationView(filename: kind.lottieFilename)
                }
                .frame(width: 140, height: 140)
                .clipped()
                .offset(y: 44)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Close")

                Spacer()

                Menu {
                    Button("Подробнее", systemImage: "info.circle") {}
                    Button("Пожаловаться", systemImage: "exclamationmark.bubble", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Options")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
        }
        .padding(.bottom, 46)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            pill(emoji: "💎", title: "Передать") { Haptics.light() }
            pill(emoji: "👑", title: isWorn ? "Снято" : "Носить", filled: isWorn) {
                Haptics.medium()
                onWear()
            }
            pill(emoji: "🏷️", title: "Продать") { Haptics.light() }
        }
    }

    private func pill(emoji: String, title: String, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(emoji)
                    .font(.footnote)
                Text(title)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(filled ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                filled
                    ? AnyShapeStyle(Color.purple.gradient)
                    : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(.purple.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Attribute table

    private var attributeTable: some View {
        VStack(spacing: 0) {
            row(title: "Владелец", value: ownerName)
            divider
            badgeRow(title: "Модель", value: kind.modelName ?? "", badge: kind.modelRarity)
            divider
            badgeRow(title: "Узор", value: kind.patternName ?? "", badge: kind.patternRarity)
            divider
            badgeRow(title: "Фон", value: kind.backgroundName ?? "", badge: kind.backgroundRarity)
            divider
            row(title: "Наличие", value: kind.supplyLabel ?? "")
            divider
            row(title: "Ценность", value: kind.marketValueLabel ?? "")
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func badgeRow(title: String, value: String, badge: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
            Text(badge)
                .font(.system(size: 10, weight: .bold))
                .monospaced()
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.purple.opacity(0.75), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var divider: some View {
        Divider().padding(.leading, 14)
    }
}
