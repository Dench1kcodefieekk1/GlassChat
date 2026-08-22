import SwiftUI

/// Telegram-style bottom sheet for a standard gift ($0.99 – $4.99 fiat).
struct StandardGiftDetailView: View {
    let gift: GiftItem
    let onToggleVisibility: () -> Void
    let onSendGift: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var kind: GiftKind { gift.kind }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            VStack(spacing: 14) {
                floatingGraphic

                VStack(spacing: 6) {
                    Text("Подарок Вам")
                        .font(.title3.weight(.semibold))
                    Text("Вы можете хранить этот подарок в профиле.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 6)

            VStack(spacing: 0) {
                fromRow
                divider
                attributeRow(title: "Дата", value: gift.receivedAt.giftDateTimeLabel)
                divider
                attributeRow(title: "Стоимость", value: kind.priceLabel)
            }
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )

            Spacer(minLength: 0)

            Button {
                onToggleVisibility()
            } label: {
                Text(gift.isHiddenFromProfile
                     ? "Подарок скрыт. Показать >"
                     : "Подарок виден в профиле. Скрыть >")
                    .font(.footnote)
                    .foregroundStyle(.tint)
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
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 18)
        .presentationDetents([.medium, .large])
    }

    // MARK: - Parts

    /// Lottie animation with a subtle continuous floating motion.
    private var floatingGraphic: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GiftAnimationView(filename: kind.lottieFilename)
                .frame(width: 130, height: 130)
                .offset(y: reduceMotion ? 0 : 6 * sin(t * 1.6))
        }
    }

    private var fromRow: some View {
        HStack(spacing: 10) {
            AvatarView(title: gift.senderName, seed: gift.senderName, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(gift.senderName)
                    .font(.subheadline.weight(.medium))
                Text("Отправитель")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Haptics.light()
                onSendGift()
            } label: {
                Text("Отправить подарок")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.tint.opacity(0.14), in: Capsule())
            }
            .foregroundStyle(.tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func attributeRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Divider().padding(.leading, 14)
    }
}
