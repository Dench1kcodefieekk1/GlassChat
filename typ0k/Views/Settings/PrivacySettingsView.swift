import SwiftUI

struct PrivacySettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return List {
            Section {
                Picker("Last Seen & Online", selection: $store.settings.lastSeenPrivacy) {
                    ForEach(LastSeenPrivacy.allCases) { privacy in
                        Text(privacy.label).tag(privacy)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Who can see your online status and last seen time. \"My Contacts\" only reveals your status to people you share it back with.")
            }

            Section {
                Toggle("Show Profile Photo", isOn: $store.settings.showProfilePhoto)
                Toggle("Show Phone Number", isOn: $store.settings.showPhoneNumber)
                Toggle("Read Receipts", isOn: $store.settings.readReceipts)
                Toggle("Allow Calls", isOn: $store.settings.allowCalls)
            }

            Section {
                NavigationLink {
                    PasscodeSettingsView()
                } label: {
                    HStack {
                        Text("Passcode Lock")
                        Spacer()
                        Text(store.settings.passcodeEnabled ? "On" : "Off")
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    TwoStepVerificationView()
                } label: {
                    HStack {
                        Text("Two-Step Verification")
                        Spacer()
                        Text(store.settings.twoStepEnabled ? "On" : "Off")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Security")
            } footer: {
                Text("Passcode and two-step settings in this prototype are stored locally on the device and are for demonstration only.")
            }

            Section {
                NavigationLink {
                    BlockedUsersView()
                } label: {
                    HStack {
                        Text("Blocked Users")
                        Spacer()
                        if !store.settings.blockedUserIDs.isEmpty {
                            Text("\(store.settings.blockedUserIDs.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .autosaveSettings(store)
        .onChange(of: store.settings.lastSeenPrivacy) { _, newValue in
            store.settings.showLastSeen = newValue != .nobody
            PresenceService.shared.publishPrivacy(newValue)
        }
    }
}

// MARK: - Blocked users

struct BlockedUsersView: View {
    @Environment(DataStore.self) private var store

    private var blockedUsers: [User] {
        store.settings.blockedUserIDs.compactMap { store.user(id: $0) }
    }

    var body: some View {
        Group {
            if blockedUsers.isEmpty {
                ContentUnavailableView {
                    Label("No Blocked Users", systemImage: "hand.raised.slash")
                } description: {
                    Text("Users you block will appear here. Blocked users can't send you messages or see your last seen.")
                }
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: 12) {
                            AvatarView(title: user.name, seed: user.id, size: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(user.name)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Unblock") {
                                unblock(user)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unblock(_ user: User) {
        Haptics.light()
        store.settings.blockedUserIDs.removeAll { $0 == user.id }
        store.save()
    }
}
