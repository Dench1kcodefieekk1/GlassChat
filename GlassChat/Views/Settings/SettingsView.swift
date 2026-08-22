import SwiftUI

struct SettingsHomeView: View {
    @Environment(DataStore.self) private var store
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var model = SettingsViewModel()
    @State private var showAddAccount = false

    private var me: User { store.currentUser }

    var body: some View {
        List {
            profileCardSection
            accountSection
            if !store.settings.linkedAccounts.isEmpty {
                accountsSwitchSection
            }
            generalSection
            otherSection
            logoutSection
            addAccountSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Settings")
        .onChange(of: store.settings) {
            store.save()
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
        }
    }

    // MARK: - Profile card

    private var profileCardSection: some View {
        Section {
            NavigationLink {
                UserProfileView()
            } label: {
                HStack(spacing: 14) {
                    AvatarView(
                        title: me.name,
                        seed: me.id,
                        size: 62,
                        isOnline: true,
                        fileName: me.avatarFileName
                    )
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
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .listRowBackground(
                Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55)
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                UserProfileView()
            } label: {
                settingsIcon("person.crop.circle.fill", color: .accentColor)
                Text("My Profile")
            }
        }
    }

    // MARK: - Add account (bottom)

    private var addAccountSection: some View {
        Section {
            Button {
                Haptics.light()
                showAddAccount = true
            } label: {
                HStack {
                    settingsIcon("person.badge.plus", color: .green)
                    Text("Add Account")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Account switching

    private var accountsSwitchSection: some View {
        Section("Switch Account") {
            Button {
                switchAccount(to: User.currentID)
            } label: {
                accountRow(name: store.user(id: User.currentID)?.name ?? "Alex",
                           phone: store.user(id: User.currentID)?.phone ?? "",
                           isSelected: store.currentUserID == User.currentID)
            }
            ForEach(store.settings.linkedAccounts) { account in
                Button {
                    switchAccount(to: account.id)
                } label: {
                    accountRow(name: account.name, phone: account.phone,
                               isSelected: store.currentUserID == account.id)
                }
            }
        }
    }

    private func accountRow(name: String, phone: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(title: name, seed: name, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(phone)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    private func switchAccount(to userID: String) {
        guard store.currentUserID != userID else { return }
        Haptics.light()
        store.currentUserID = userID
        store.save()
    }

    // MARK: - General

    private var generalSection: some View {
        Section("General") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                settingsIcon("bell.badge.fill", color: .red)
                Text("Notifications and Sounds")
            }

            NavigationLink {
                PrivacySettingsView()
            } label: {
                settingsIcon("hand.raised.fill", color: .teal)
                Text("Privacy")
            }

            NavigationLink {
                SessionsSettingsView()
            } label: {
                settingsIcon("desktopcomputer", color: .indigo)
                Text("Active Sessions")
            }

            NavigationLink {
                AppearanceSettingsView()
            } label: {
                settingsIcon("paintbrush.fill", color: .purple)
                Text("Appearance")
            }

            NavigationLink {
                ChatSettingsView()
            } label: {
                settingsIcon("bubble.left.and.bubble.right.fill", color: .green)
                Text("Chats")
            }
        }
    }

    // MARK: - Other

    private var otherSection: some View {
        Section("Other") {
            HStack {
                settingsIcon("externaldrive.fill", color: .orange)
                Text("Storage Usage")
                Spacer()
                Text(model.storageBytes, format: .byteCount(style: .file))
                    .foregroundStyle(.secondary)
            }
            Button {
                model.showClearConfirmation = true
            } label: {
                settingsIcon("trash.fill", color: .red)
                Text("Clear Cache")
            }
            .confirmationDialog("Clear cached media?", isPresented: $model.showClearConfirmation, titleVisibility: .visible) {
                Button("Clear Cache", role: .destructive) {
                    model.clearCache()
                }
            } message: {
                Text("Previously sent photos and voice messages will no longer be available offline.")
            }

            NavigationLink {
                LanguageSettingsView()
            } label: {
                settingsIcon("globe", color: .blue)
                Text("Language")
            }

            NavigationLink {
                AboutSettingsView()
            } label: {
                settingsIcon("info.circle.fill", color: .gray)
                Text("About")
            }
        }
        .onAppear { model.refreshStorage() }
    }

    private var logoutSection: some View {
        Section {
            Button {
                Haptics.light()
                isLoggedIn = false
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.red)
        }
    }

    private func settingsIcon(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 29, height: 29)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Add account

struct AddAccountSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var path: [AuthStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            PhoneNumberView { fullNumber in
                path.append(.otp(fullNumber))
            }
            .navigationDestination(for: AuthStep.self) { step in
                if case .otp(let number) = step {
                    OTPView(
                        phoneNumber: number,
                        onAuthenticated: {
                            Haptics.success()
                            addAccount(phone: number)
                            dismiss()
                        },
                        onBack: {
                            if !path.isEmpty { path.removeLast() }
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addAccount(phone: String) {
        let id = "user-account-\(UUID().uuidString)"
        let name = "Account \(phone)"
        let user = User(
            id: id,
            name: name,
            username: "user" + phone.filter(\.isNumber).suffix(6),
            bio: "",
            phone: phone
        )
        store.users[id] = user
        store.settings.linkedAccounts.append(LinkedAccount(id: id, name: name, phone: phone))
        store.currentUserID = id
        store.save()
    }
}

// MARK: - Language

struct LanguageSettingsView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        @Bindable var store = store
        return List {
            Section {
                Picker("Language", selection: $store.settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text("GlassChat is a prototype and currently ships in English only. The choice is persisted and will apply once translations are added.")
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .autosaveSettings(store)
    }
}

// MARK: - About

struct AboutSettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var model = SettingsViewModel()
    @State private var showLicenses = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GlassChat")
                            .font(.headline)
                        Text("Version \(model.appVersion) (\(model.buildNumber))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("GlassChat Team")
                        .foregroundStyle(.secondary)
                }
                Button {
                    showLicenses = true
                } label: {
                    Text("Licenses")
                        .foregroundStyle(.primary)
                }
            }
            Section {
                Text("GlassChat is an original messenger prototype built with SwiftUI and iOS 26 Liquid Glass. It is not affiliated with Telegram or any other messaging service.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLicenses) {
            LicensesView(text: model.licensesText)
        }
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
