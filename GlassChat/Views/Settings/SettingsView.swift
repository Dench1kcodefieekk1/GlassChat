import SwiftUI

struct SettingsHomeView: View {
    @Environment(DataStore.self) private var store
    @State private var model = SettingsViewModel()
    @State private var showEditProfile = false

    var body: some View {
        Form {
            accountSection
            appearanceSection
            chatsSection
            notificationsSection
            privacySection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .onChange(of: store.settings) {
            store.save()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $model.showLicenses) {
            LicensesView(text: model.licensesText)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            Button {
                showEditProfile = true
            } label: {
                HStack(spacing: 14) {
                    let me = store.currentUser
                    AvatarView(title: me.name, seed: me.id, size: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(me.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("@\(me.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(me.phone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        @Bindable var store = store
        return Section("Appearance") {
            Picker("Theme", selection: $store.settings.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 14) {
                ForEach(AccentChoice.allCases) { choice in
                    Button {
                        store.settings.accent = choice
                    } label: {
                        Circle()
                            .fill(choice.color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if store.settings.accent == choice {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .accessibilityLabel(choice.label)
                }
                Spacer()
            }
        }
    }

    // MARK: - Chats

    private var chatsSection: some View {
        @Bindable var store = store
        return Section("Chats") {
            Toggle("Send with Return", isOn: $store.settings.enterToSend)
            Toggle("Message Previews", isOn: $store.settings.messagePreviews)
            Toggle("Auto-Download Media", isOn: $store.settings.autoDownloadMedia)
            Toggle("Save Incoming Media", isOn: $store.settings.saveIncomingMedia)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        @Bindable var store = store
        return Section("Notifications") {
            Toggle("Messages", isOn: $store.settings.notifyMessages)
            Toggle("Sounds", isOn: $store.settings.notifySounds)
            Toggle("Message Preview", isOn: $store.settings.notifyPreview)
            Toggle("Mentions", isOn: $store.settings.notifyMentions)
        }
        .onChange(of: store.settings.notifyMessages) { _, enabled in
            if enabled {
                Task {
                    _ = await NotificationService.shared.requestAuthorization()
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        @Bindable var store = store
        return Section("Privacy") {
            Toggle("Show Last Seen", isOn: $store.settings.showLastSeen)
            Toggle("Show Profile Photo", isOn: $store.settings.showProfilePhoto)
            Toggle("Read Receipts", isOn: $store.settings.readReceipts)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data and Storage") {
            HStack {
                Label("Storage Usage", systemImage: "externaldrive.fill")
                Spacer()
                Text(model.storageBytes, format: .byteCount(style: .file))
                    .foregroundStyle(.secondary)
            }
            Button("Clear Cache", role: .destructive) {
                model.showClearConfirmation = true
            }
            .confirmationDialog("Clear cached media?", isPresented: $model.showClearConfirmation, titleVisibility: .visible) {
                Button("Clear Cache", role: .destructive) {
                    model.clearCache()
                }
            } message: {
                Text("Previously sent photos and voice messages will no longer be available offline.")
            }
        }
        .onAppear { model.refreshStorage() }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(model.appVersion) (\(model.buildNumber))")
                    .foregroundStyle(.secondary)
            }
            Button {
                model.showLicenses = true
            } label: {
                HStack {
                    Text("Licenses")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            HStack {
                Text("Developer")
                Spacer()
                Text("GlassChat Team")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Edit profile

struct EditProfileView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var username: String
    @State private var bio: String
    @State private var phone: String

    init() {
        _name = State(initialValue: "")
        _username = State(initialValue: "")
        _bio = State(initialValue: "")
        _phone = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let me = store.currentUser
                    AvatarView(title: name.isEmpty ? me.name : name, seed: me.id, size: 84)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                Section("Name") {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                }
                Section("Bio") {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Phone") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmed.isEmpty)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
        .presentationDetents([.large])
    }

    private func loadIfNeeded() {
        guard name.isEmpty, username.isEmpty else { return }
        let me = store.currentUser
        name = me.name
        username = me.username
        bio = me.bio
        phone = me.phone
    }

    private func save() {
        var me = store.currentUser
        me.name = name.trimmed
        me.username = username.trimmed.lowercased()
        me.bio = bio.trimmed
        me.phone = phone.trimmed
        store.users[me.id] = me
        store.save()
        dismiss()
    }
}

struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss
    let text: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
