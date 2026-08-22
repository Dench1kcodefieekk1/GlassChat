import SwiftUI

/// 2-column frame picker: every catalog frame previewed live on the user's
/// own avatar, with lock badges for frames above the current level.
struct AvatarFramePickerSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    private var me: User { store.currentUser }

    var body: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    frameCell(.none)

                    ForEach(AvatarFrameManager.catalog) { frame in
                        frameCell(.some(frame))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .presentationDetents([.large])
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Рамки аватара")
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

    // MARK: - Cells

    private func frameCell(_ frame: AvatarFrame?) -> some View {
        let level = UserLevelManager.shared.currentLevel
        let isEquipped = me.selectedFrameId == frame?.id
        let unlocked = frame.map { AvatarFrameManager.isUnlocked($0, level: level) } ?? true

        return Button {
            guard unlocked else { return }
            Haptics.light()
            if let frame {
                AvatarFrameManager.equip(frame, in: store)
            } else {
                AvatarFrameManager.unequip(in: store)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarFrameOverlayView(
                        frame: (unlocked ? frame : nil) as AvatarFrame?,
                        avatarSize: 74
                    ) {
                        AvatarView(title: me.name, seed: me.id, size: 74, isOnline: true, fileName: me.avatarFileName)
                    }

                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.tint)
                            .background(.white, in: Circle())
                    } else if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Circle().fill(.black.opacity(0.55)))
                    }
                }

                Text(frame?.name ?? "Без рамки")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let frame, !unlocked {
                    Text("Открывается на \(frame.requiredLevel) уровне")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if frame == nil {
                    Text("Сбросить оформление")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                } else if frame?.isAnimated == true {
                    Text("Анимированная")
                        .font(.system(size: 9))
                        .foregroundStyle(.tint)
                } else {
                    Text("Статичная")
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
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isEquipped ? Color.blue.opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(frame?.name ?? "Без рамки")
        .accessibilityHint(unlocked ? "Надеть рамку" : "Заблокировано")
    }
}
