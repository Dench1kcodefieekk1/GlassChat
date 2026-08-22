import SwiftUI

struct UsernameEditView: View {
    @Binding var username: String
    @Environment(\.dismiss) private var dismiss

    @State private var draft: String = ""
    @State private var showError = false

    private static let minimumLength = 5

    private var validationMessage: String? {
        if draft.count < Self.minimumLength {
            return "Username must be at least \(Self.minimumLength) characters."
        }
        return nil
    }

    private var isValid: Bool { validationMessage == nil && !draft.isEmpty }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 2) {
                    Text("@")
                        .foregroundStyle(.secondary)
                    TextField("username", text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .onChange(of: draft) { _, newValue in
                            let filtered = newValue
                                .lowercased()
                                .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                            if filtered != newValue {
                                draft = filtered
                            }
                            showError = false
                        }
                }
            } header: {
                Text("Username")
            } footer: {
                if showError, let message = validationMessage {
                    Text(message).foregroundStyle(.red)
                } else {
                    Text("Lowercase letters, digits and underscores, at least \(Self.minimumLength) characters. This is a local prototype check — no server availability lookup.")
                }
            }
        }
        .navigationTitle("Username")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard isValid else {
                        showError = true
                        Haptics.error()
                        return
                    }
                    username = draft
                    Haptics.light()
                    dismiss()
                }
                .disabled(draft.isEmpty)
            }
        }
        .onAppear { draft = username }
    }
}
