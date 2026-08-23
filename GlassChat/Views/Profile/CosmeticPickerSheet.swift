import SwiftUI

/// Premium cosmetic picker: all avatar decorations and nickname text
/// effects in one place, previewed live on the user's own avatar and name.
struct CosmeticPickerSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let frameColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    private let styleColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    private var me: User { store.currentUser }
    private var level: Int { UserLevelManager.shared.currentLevel }
    private var activeFrameID: String? {
        AvatarFrameManager.activeFrame(selectedID: me.selectedFrameId, level: level)?.id
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    framesSection
                    stylesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .presentationDetents([.large])
        .presentationSizing(.formSheet)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Оформление")
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

    // MARK: - Frames

    private var framesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Рамки аватара")
            LazyVGrid(columns: frameColumns, spacing: 12) {
                frameCell(nil)

                ForEach(AvatarFrameManager.catalog) { frame in
                    frameCell(frame)
                }
            }
        }
    }

    private func frameCell(_ frame: AvatarFrame?) -> some View {
        let unlocked = frame.map { AvatarFrameManager.isUnlocked($0, level: level) } ?? true
        let equipped = activeFrameID == frame?.id && (frame != nil || me.selectedFrameId == nil)

        return Button {
            guard unlocked else { return }
            Haptics.light()
            if let frame {
                AvatarFrameManager.equip(frame, in: store)
            } else {
                AvatarFrameManager.unequip(in: store)
            }
        } label: {
            VStack(spacing: 7) {
                AnimatedAvatarView(
                    name: me.name,
                    seed: me.id,
                    avatarFileName: me.avatarFileName,
                    size: 68,
                    frame: frame
                )
                // Fixed centered bounds: wings/auras never distort card spacing.
                .frame(width: 90, height: 90, alignment: .center)
                // Locked designs stay inspectable — dimmed, never hidden.
                .opacity(unlocked ? 1 : 0.5)
                .overlay(alignment: .bottomTrailing) {
                    if equipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.tint)
                            .background(.white, in: Circle())
                    }
                }

                Text(frame?.name ?? "Без рамки")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(frame.map { $0.isAnimated ? "Анимированная" : "Статичная" } ?? "Сбросить оформление")
                    .font(.system(size: 9))
                    .foregroundStyle(frame?.isAnimated == true ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(alignment: .topTrailing) {
                if let frame, !unlocked {
                    lockPill(level: frame.requiredLevel)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(equipped ? Color.blue.opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(frame?.name ?? "Без рамки")
    }

    // MARK: - Nickname styles

    private var stylesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Стили ника")
            LazyVGrid(columns: styleColumns, spacing: 12) {
                ForEach(NicknameStyleInfo.all) { info in
                    styleCell(info)
                }
            }
        }
    }

    private func styleCell(_ info: NicknameStyleInfo) -> some View {
        let styles = NicknameStyleManager.shared
        let unlocked = styles.isUnlocked(info.id, level: level)
        let active = unlocked && styles.activeID == info.id

        return Button {
            guard unlocked else { return }
            Haptics.light()
            styles.select(info.id)
        } label: {
            VStack(spacing: 8) {
                AnimatedNicknameView(
                    name: me.name,
                    style: info.id,
                    font: .title3.weight(.semibold)
                )
                // Locked designs stay inspectable — dimmed, never hidden.
                .opacity(unlocked ? 1 : 0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: 34)

                Text(info.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if unlocked {
                    Text(active ? "Активен" : "Выбрать")
                        .font(.system(size: 9))
                        .foregroundStyle(active ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                } else {
                    Text("Недоступно")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(alignment: .topTrailing) {
                if !unlocked {
                    lockPill(level: info.requiredLevel)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(active ? Color.blue.opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(info.title)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 4)
    }

    /// Subtle lock capsule pinned to the top-right corner of locked cards.
    private func lockPill(level: Int) -> some View {
        Text("🔒 \(level) LVL")
            .font(.system(size: 8.5, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.6), in: Capsule())
            .padding(6)
    }
}
