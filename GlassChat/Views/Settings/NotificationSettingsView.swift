import SwiftUI

struct NotificationSettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return List {
            Section("Messages") {
                Toggle("Notifications", isOn: $store.settings.notifyMessages)
                Toggle("Message Preview", isOn: $store.settings.notifyPreview)
                Toggle("Mentions", isOn: $store.settings.notifyMentions)
                Toggle("Reactions", isOn: $store.settings.notifyReactions)
            }
            .onChange(of: store.settings.notifyMessages) { _, enabled in
                if enabled {
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                    }
                }
            }

            Section("Sounds") {
                Toggle("Sounds", isOn: $store.settings.notifySounds)
                if store.settings.notifySounds {
                    Picker("Notification Sound", selection: $store.settings.notificationSound) {
                        ForEach(NotificationSound.allCases) { sound in
                            Text(sound.label).tag(sound)
                        }
                    }
                }
            }

            Section {
                Toggle("Badge Count", isOn: $store.settings.badgeCount)
                Toggle("Include Muted Chats", isOn: $store.settings.badgeIncludeMuted)
            } header: {
                Text("Badges")
            } footer: {
                Text("When Include Muted Chats is on, unread messages in muted chats also count toward the app badge.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .autosaveSettings(store)
    }
}
