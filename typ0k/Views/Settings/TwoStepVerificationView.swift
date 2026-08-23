import SwiftUI

struct TwoStepVerificationView: View {
    @Environment(DataStore.self) private var store
    @State private var showPasswordEntry = false
    @State private var entryMode: TwoStepEntryMode = .enable

    var body: some View {
        @Bindable var store = store
        return List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(store.settings.twoStepEnabled ? "Enabled" : "Disabled")
                        .foregroundStyle(store.settings.twoStepEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                }
            } footer: {
                Text("When enabled, you'll need this password in addition to the SMS code when signing in. This prototype stores only a local hash.")
            }

            Section {
                if store.settings.twoStepEnabled {
                    Button("Change Password") {
                        Haptics.light()
                        entryMode = .change
                        showPasswordEntry = true
                    }
                    Button("Turn Off", role: .destructive) {
                        Haptics.light()
                        store.settings.twoStepEnabled = false
                        store.settings.twoStepPasswordHash = nil
                        store.save()
                    }
                } else {
                    Button("Enable Two-Step Verification") {
                        Haptics.light()
                        entryMode = .enable
                        showPasswordEntry = true
                    }
                }
            }

            Section("Recovery Email") {
                TextField("email@example.com", text: $store.settings.recoveryEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle("Two-Step Verification")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPasswordEntry) {
            TwoStepPasswordSheet(mode: entryMode) { hash in
                store.settings.twoStepPasswordHash = hash
                store.settings.twoStepEnabled = true
                store.save()
                Haptics.success()
            }
        }
        .autosaveSettings(store)
    }
}

enum TwoStepEntryMode {
    case enable
    case change
}

struct TwoStepPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mode: TwoStepEntryMode
    let onSave: (String) -> Void

    @State private var password = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?

    private var isValid: Bool {
        password.count >= 6 && password == confirmation
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Password (at least 6 characters)", text: $password)
                    SecureField("Repeat password", text: $confirmation)
                } footer: {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(mode == .enable ? "Enable Verification" : "Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard password.count >= 6 else {
                            errorMessage = "Password must be at least 6 characters."
                            Haptics.error()
                            return
                        }
                        guard password == confirmation else {
                            errorMessage = "Passwords don't match."
                            Haptics.error()
                            return
                        }
                        onSave(PasscodeEntrySheet.hash(password))
                        dismiss()
                    }
                    .disabled(password.isEmpty || confirmation.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
