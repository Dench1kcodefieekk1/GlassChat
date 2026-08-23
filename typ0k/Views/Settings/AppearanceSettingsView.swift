import SwiftUI

struct AccentPickerView: View {
    let selection: AccentChoice
    let onSelect: (AccentChoice) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(AccentChoice.allCases) { choice in
                Button {
                    guard choice != selection else { return }
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onSelect(choice)
                    }
                } label: {
                    Circle()
                        .fill(choice.color.gradient)
                        .frame(width: 34, height: 34)
                        .overlay {
                            if selection == choice {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .overlay {
                            if selection == choice {
                                Circle()
                                    .stroke(choice.color.opacity(0.45), lineWidth: 2)
                                    .padding(-4)
                            }
                        }
                        .scaleEffect(selection == choice ? 1.06 : 1)
                }
                .buttonStyle(PressScaleButtonStyle(scale: 0.85))
                .accessibilityLabel(choice.label)
                .accessibilityAddTraits(selection == choice ? .isSelected : [])
            }
            Spacer()
        }
    }
}

struct AppearanceSettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return List {
            Section("Theme") {
                Picker("Theme", selection: $store.settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Accent Color") {
                AccentPickerView(selection: store.settings.accent) { choice in
                    store.settings.accent = choice
                }
                .padding(.vertical, 4)
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.fill")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Messages and controls follow the accent color across the whole app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .autosaveSettings(store)
    }
}
