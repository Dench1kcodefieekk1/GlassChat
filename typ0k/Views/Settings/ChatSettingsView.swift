import SwiftUI

struct ChatSettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return List {
            Section("Appearance") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Message Text Size")
                        Spacer()
                        Text("\(Int(store.settings.messageTextSize))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $store.settings.messageTextSize, in: 14...22, step: 1)
                    Text("The quick brown fox jumps over the lazy dog")
                        .font(.system(size: store.settings.messageTextSize))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                NavigationLink {
                    WallpaperPickerView()
                } label: {
                    HStack {
                        Text("Chat Wallpaper")
                        Spacer()
                        Text(store.settings.wallpaper.label)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Bubble Style", selection: $store.settings.bubbleStyle) {
                    ForEach(BubbleStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
            }

            Section("Auto-Download Media") {
                Toggle("Photos", isOn: $store.settings.autoDownloadPhotos)
                Toggle("Videos", isOn: $store.settings.autoDownloadVideos)
                Toggle("Files", isOn: $store.settings.autoDownloadFiles)
            }

            Section("Behavior") {
                Toggle("Send with Return", isOn: $store.settings.enterToSend)
                Toggle("Save Incoming Media", isOn: $store.settings.saveIncomingMedia)
                Toggle("Link Previews", isOn: $store.settings.linkPreviews)
                Toggle("Auto-Play Videos", isOn: $store.settings.autoPlayVideos)
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .autosaveSettings(store)
    }
}

// MARK: - Wallpaper picker

struct WallpaperPickerView: View {
    @Environment(DataStore.self) private var store

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(ChatWallpaper.allCases) { wallpaper in
                    wallpaperCell(wallpaper)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Chat Wallpaper")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wallpaperCell(_ wallpaper: ChatWallpaper) -> some View {
        let isSelected = store.settings.wallpaper == wallpaper
        return Button {
            guard !isSelected else { return }
            Haptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                store.settings.wallpaper = wallpaper
                store.save()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    ChatWallpaperView(wallpaper: wallpaper)
                        .frame(height: 140)
                        .overlay(alignment: .topLeading) {
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.tint)
                                    .frame(width: 44, height: 14)
                                Spacer()
                            }
                            .padding(10)
                        }
                        .overlay(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .frame(width: 56, height: 14)
                                .padding(10)
                        }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .tint)
                            .padding(8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), lineWidth: isSelected ? 2 : 1)
                )

                Text(wallpaper.label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            }
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.96))
        .accessibilityLabel("\(wallpaper.label) wallpaper")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
