import SwiftUI

/// Shown once after registration when `users/{uid}` has no completed
/// profile yet. Display name is required; the username is optional
/// (Telegram-style — it may be left blank).
struct ProfileSetupView: View {
    var onComplete: (_ displayName: String, _ username: String?) -> Void

    @State private var displayName = ""
    @State private var username = ""
    @FocusState private var focused: Bool

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedUsername: String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Your Profile")
                    .font(.largeTitle.bold())
                Text("This is how other people will see you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            VStack(spacing: 10) {
                TextField("Display Name (required)", text: $displayName)
                    .font(.body.weight(.medium))
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .accessibilityLabel("Display name")

                TextField("Username (optional)", text: $username)
                    .font(.body.weight(.medium))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.twitter)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(fieldBackground)
                    .accessibilityLabel("Username, optional")
            }

            Button {
                Haptics.medium()
                onComplete(trimmedName, trimmedUsername.isEmpty ? nil : trimmedUsername)
            } label: {
                Text("Start Messaging")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .disabled(trimmedName.isEmpty)

            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("Profile Setup")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { focused = true }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
