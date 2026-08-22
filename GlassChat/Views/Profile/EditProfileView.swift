import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var bio: String
    @State private var username: String
    @AppStorage("userPhone") private var phone = "+380 99 123 4567"
    @State private var personalAccent: AccentChoice
    @State private var linkedChannel: String
    @State private var pendingAvatar: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    private let userID: String

    init(userID: String = User.currentID) {
        self.userID = userID
        _firstName = State(initialValue: "")
        _lastName = State(initialValue: "")
        _bio = State(initialValue: "")
        _username = State(initialValue: "")
        _personalAccent = State(initialValue: .blue)
        _linkedChannel = State(initialValue: "")
    }

    private var me: User { store.user(id: userID) ?? store.currentUser }
    private var bioRemaining: Int { 70 - bio.count }

    var body: some View {
        Form {
            avatarSection
            nameSection
            bioSection
            infoSection
            accentSection
            channelSection
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    save()
                }
                .font(.body.weight(.semibold))
                .disabled(firstName.trimmed.isEmpty)
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    Haptics.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        pendingAvatar = image
                    }
                }
                pickerItem = nil
            }
        }
        .onChange(of: bio) { _, newValue in
            if newValue.count > 70 {
                bio = String(newValue.prefix(70))
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        Section {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let pendingAvatar {
                            Image(uiImage: pendingAvatar)
                                .resizable()
                                .scaledToFill()
                        } else {
                            AvatarView(title: displayNamePreview, seed: userID, size: 92, fileName: me.avatarFileName)
                        }
                    }
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())

                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.tint))
                }
            }
            .accessibilityLabel("Change profile photo")
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private var displayNamePreview: String {
        let name = [firstName.trimmed, lastName.trimmed].filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? me.name : name
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("First name", text: $firstName)
            TextField("Last name", text: $lastName)
        }
    }

    private var bioSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if bio.isEmpty {
                    Text("Bio")
                        .foregroundStyle(Color(uiColor: .placeholderText))
                        .padding(.top, 8)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $bio)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Bio")
        } footer: {
            HStack {
                Text("Anything interesting about you.")
                Spacer()
                Text("\(bio.count) / 70")
                    .monospacedDigit()
                    .foregroundStyle(bioRemaining <= 10 ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            }
        }
    }

    private var infoSection: some View {
        Section {
            NavigationLink {
                UsernameEditView(username: $username)
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Username")
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                PhoneChangeView(phone: $phone)
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Phone Number")
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accentSection: some View {
        Section("Personal Accent") {
            AccentPickerView(selection: personalAccent) { choice in
                personalAccent = choice
            }
            .padding(.vertical, 4)
        }
    }

    private var channelSection: some View {
        Section {
            NavigationLink {
                ChannelLinkingView(selection: $linkedChannel)
            } label: {
                HStack {
                    Text("Link a Channel")
                    Spacer()
                    Text(linkedChannel.isEmpty ? "None" : linkedChannel)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Load / Save

    private func loadIfNeeded() {
        guard firstName.isEmpty, username.isEmpty else { return }
        let parts = me.name.split(separator: " ", maxSplits: 1).map(String.init)
        firstName = parts.first ?? me.name
        lastName = parts.count > 1 ? parts[1] : ""
        bio = me.bio
        username = me.username
        personalAccent = me.personalAccent ?? store.settings.accent
        linkedChannel = me.linkedChannel ?? ""
    }

    private func save() {
        var updated = me
        updated.name = displayNamePreview
        updated.bio = bio.trimmed
        updated.username = username.trimmed.lowercased()
        updated.phone = phone.trimmed
        updated.personalAccent = personalAccent
        updated.linkedChannel = linkedChannel.isEmpty ? nil : linkedChannel

        if let pendingAvatar {
            let scaled = MediaService.downscale(pendingAvatar, maxDimension: 512)
            if let data = scaled.jpegData(compressionQuality: 0.85) {
                if let old = updated.avatarFileName {
                    MediaService.delete(old)
                }
                updated.avatarFileName = MediaService.save(data, extension: "jpg")
            }
        }

        store.users[updated.id] = updated
        store.save()
        Haptics.success()
        dismiss()
    }
}

// MARK: - Phone change (reuses the existing auth component)

struct PhoneChangeView: View {
    @Binding var phone: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PhoneNumberView { fullNumber in
            phone = fullNumber
            Haptics.light()
            dismiss()
        }
        .navigationTitle("Change Number")
    }
}
