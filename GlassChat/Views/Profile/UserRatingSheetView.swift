import SwiftUI

/// Telegram/Discord-style rating modal: XP status bubble, level progress,
/// earning rules, and the nickname style picker with unlock badges.
struct UserRatingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    private let manager = UserLevelManager.shared
    private let styles = NicknameStyleManager.shared

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
                    stylePicker
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
                text: "10 XP за сообщение + 1 XP за символ"
            )
            divider
            ruleRow(
                icon: "calendar.badge.clock",
                tint: .blue,
                text: "500 XP каждый день при заходе"
            )
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func ruleRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            (Text("плюс").bold() + Text(" \(text)"))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Nickname styles

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Стили ника")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(NicknameStyleInfo.all.enumerated()), id: \.element.id) { index, info in
                    styleRow(info)
                    if index < NicknameStyleInfo.all.count - 1 {
                        divider
                    }
                }
            }
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    @ViewBuilder
    private func styleRow(_ info: NicknameStyleInfo) -> some View {
        let unlocked = styles.isUnlocked(info.id, level: manager.currentLevel)
        let isActive = unlocked && styles.activeID == info.id

        Button {
            guard unlocked else { return }
            Haptics.light()
            styles.select(info.id)
        } label: {
            HStack(spacing: 12) {
                NicknameStyleSwatch(style: info.id)

                Text(info.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                if isActive {
                    Label("Активен", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                } else if unlocked {
                    Text("Выбрать")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                } else {
                    Label("Открывается на \(info.requiredLevel) уровне", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(info.title)
        .accessibilityHint(unlocked ? "Выбрать стиль ника" : "Заблокировано до уровня \(info.requiredLevel)")
    }

    private var divider: some View {
        Divider().padding(.leading, 52)
    }
}
