import SwiftUI
import CryptoKit

struct PasscodeSettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var showPasscodeEntry = false
    @State private var entryMode: PasscodeEntryMode = .create

    var body: some View {
        @Bindable var store = store
        return List {
            Section {
                Toggle("Enable Passcode", isOn: Binding(
                    get: { store.settings.passcodeEnabled },
                    set: { newValue in
                        if newValue {
                            entryMode = .create
                            showPasscodeEntry = true
                        } else {
                            Haptics.light()
                            store.settings.passcodeEnabled = false
                            store.settings.passcodeHash = nil
                            store.save()
                        }
                    }
                ))
            } footer: {
                Text("The passcode is stored as a SHA-256 hash on this device. This is a local prototype control, not cryptographic protection.")
            }

            if store.settings.passcodeEnabled {
                Section {
                    Button("Change Passcode") {
                        Haptics.light()
                        entryMode = .change
                        showPasscodeEntry = true
                    }
                    Picker("Auto-Lock", selection: $store.settings.autoLock) {
                        ForEach(AutoLockOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }
            }
        }
        .navigationTitle("Passcode Lock")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPasscodeEntry) {
            PasscodeEntrySheet(mode: entryMode) { hash in
                store.settings.passcodeHash = hash
                store.settings.passcodeEnabled = true
                store.save()
                Haptics.success()
            }
        }
        .autosaveSettings(store)
    }
}

enum PasscodeEntryMode {
    case create
    case change
}

struct PasscodeEntrySheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let mode: PasscodeEntryMode
    let onSave: (String) -> Void

    @State private var passcode = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?

    private var isValid: Bool {
        passcode.count == 4 && confirmation == passcode
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("4-digit passcode", text: $passcode)
                        .keyboardType(.numberPad)
                        .onChange(of: passcode) { _, value in
                            passcode = String(value.filter(\.isNumber).prefix(4))
                        }
                    SecureField("Repeat passcode", text: $confirmation)
                        .keyboardType(.numberPad)
                        .onChange(of: confirmation) { _, value in
                            confirmation = String(value.filter(\.isNumber).prefix(4))
                        }
                } footer: {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    } else {
                        Text("Enter a 4-digit passcode twice.")
                    }
                }
            }
            .navigationTitle(mode == .create ? "Set Passcode" : "Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard isValid else {
                            errorMessage = passcode.count < 4
                                ? "Passcode must be 4 digits."
                                : "Passcodes don't match."
                            Haptics.error()
                            return
                        }
                        onSave(Self.hash(passcode))
                        dismiss()
                    }
                    .disabled(passcode.count < 4 || confirmation.count < 4)
                }
            }
        }
        .presentationDetents([.medium])
    }

    static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
