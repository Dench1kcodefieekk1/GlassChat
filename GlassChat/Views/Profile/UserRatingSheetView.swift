import SwiftUI

/// Telegram-style rating modal: XP status bubble, dual-ended level progress,
/// activity rules breakdown, and the OK action.
struct UserRatingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    private let manager = UserLevelManager.shared

    private var nextLevelLabel: String {
        manager.currentLevel >= UserLevelManager.maxLevel
            ? "МАКС"
            : "Уровень \(manager.currentLevel + 1)"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 18) {
                    xpBubble
                    progressSection
                    rulesCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }

            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text("👌 OK")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.16, green: 0.35, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .presentationDetents([.medium, .large])
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Рейтинг")
                .font(.headline)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                }
                .accessibilityLabel("Close")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - XP status bubble

    private var xpBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 17, weight: .bold))
            Text("\(manager.currentXP) / \(manager.requiredXP) XP")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.42, green: 0.3, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .shadow(color: Color.blue.opacity(0.35), radius: 12, y: 4)
        .padding(.top, 8)
        .accessibilityLabel("\(manager.currentXP) из \(manager.requiredXP) опыта")
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 7) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.42, green: 0.3, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * manager.progress))
                }
            }
            .frame(height: 10)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: manager.progress)

            HStack {
                Text("Уровень \(manager.currentLevel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(nextLevelLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Rules

    private var rulesCard: some View {
        VStack(spacing: 0) {
            ruleRow(
                icon: "bubble.left.and.bubble.right.fill",
                tint: .blue,
                prefix: "плюс",
                text: " 10 XP за сообщение + 1 XP за каждый символ в тексте."
            )
            divider
            ruleRow(
                icon: "calendar.badge.clock",
                tint: .blue,
                prefix: "плюс",
                text: " 500 XP каждый день при заходе в мессенджер."
            )
            divider
            ruleRow(
                icon: "clock.arrow.circlepath",
                tint: .orange,
                prefix: "нейтрально",
                text: " Рейтинг отражает вашу реальную активность и общение в сети."
            )
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func ruleRow(icon: String, tint: Color, prefix: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            (Text(prefix).bold() + Text(text))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Divider().padding(.leading, 56)
    }
}
