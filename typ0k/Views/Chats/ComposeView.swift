import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Global username search result from the `users` Firestore collection.
struct RemoteUserResult: Identifiable, Hashable {
    let id: String
    let username: String
    let displayName: String
}

struct ComposeView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var remoteResults: [RemoteUserResult] = []
    @State private var isSearchingRemote = false
    @State private var searchTask: Task<Void, Never>?

    /// Receives the chat ID to open once the compose sheet dismisses.
    let onOpenChat: (String) -> Void

    private var contacts: [User] {
        let query = normalizedQuery
        var users = store.users.values.filter { $0.id != store.currentUserID }
        if !query.isEmpty {
            users = users.filter {
                $0.name.lowercased().contains(query) || $0.username.lowercased().contains(query)
            }
        }
        return users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Every `@` and surrounding whitespace is stripped so `@typ0k`,
    /// `typ0k`, and `@ typ0k` all build the same clean query.
    private var normalizedQuery: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    var body: some View {
        NavigationStack {
            List {
                if !contacts.isEmpty {
                    Section("Contacts") {
                        ForEach(contacts) { user in
                            Button {
                                onOpenChat(store.createDirectChat(with: user.id).id)
                            } label: {
                                contactRow(for: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !normalizedQuery.isEmpty {
                    Section("Global Search") {
                        if isSearchingRemote {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else if remoteResults.isEmpty {
                            Text("No users found for \"@\(normalizedQuery)\"")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(remoteResults) { result in
                                Button {
                                    openRemoteChat(with: result)
                                } label: {
                                    remoteRow(for: result)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search contacts or @username")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if contacts.isEmpty && remoteResults.isEmpty && normalizedQuery.isEmpty {
                    ContentUnavailableView(
                        "No contacts found",
                        systemImage: "person.crop.circle.badge.questionmark"
                    )
                }
            }
            .onChange(of: searchText) { _, newValue in
                runRemoteSearch(newValue)
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Rows

    private func contactRow(for user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(title: user.name, seed: user.id, size: 44, isOnline: user.isOnline)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }
                }
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func remoteRow(for result: RemoteUserResult) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                title: result.displayName.isEmpty ? result.username : result.displayName,
                seed: result.id,
                size: 44
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(result.username)")
                    .font(.headline)
                if !result.displayName.isEmpty {
                    Text(result.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Remote username search

    /// Case-insensitive prefix search over `users.usernameLower`
    /// (range query `>= prefix` and `<= prefix + U+F8FF`).
    private func runRemoteSearch(_ rawQuery: String) {
        searchTask?.cancel()
        let query = rawQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        guard !query.isEmpty else {
            remoteResults = []
            isSearchingRemote = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            guard FirebaseApp.app() != nil, let uid = Auth.auth().currentUser?.uid else {
                return
            }
            isSearchingRemote = true
            do {
                let snapshot = try await Firestore.firestore().collection("users")
                    .whereField("usernameLower", isGreaterThanOrEqualTo: query)
                    .whereField("usernameLower", isLessThanOrEqualTo: query + "\u{f8ff}")
                    .limit(to: 20)
                    .getDocuments()
                let results = snapshot.documents.compactMap { doc -> RemoteUserResult? in
                    guard doc.documentID != uid else { return nil }
                    let data = doc.data()
                    guard let username = data["username"] as? String, !username.isEmpty else { return nil }
                    let displayName = (data["displayName"] as? String) ?? ""
                    return RemoteUserResult(id: doc.documentID, username: username, displayName: displayName)
                }
                if !Task.isCancelled {
                    remoteResults = results
                    isSearchingRemote = false
                }
            } catch {
                print("[Compose] Username search failed: \(error.localizedDescription)")
                if !Task.isCancelled { isSearchingRemote = false }
            }
        }
    }

    // MARK: - Opening chats

    /// Tapping a global-search result creates (or opens) the deterministic
    /// direct chat `min(uid1,uid2)_max(uid1,uid2)`.
    private func openRemoteChat(with result: RemoteUserResult) {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        if store.users[result.id] == nil {
            store.users[result.id] = User(
                id: result.id,
                name: result.displayName.isEmpty ? "@\(result.username)" : result.displayName,
                username: result.username,
                bio: "",
                phone: ""
            )
        }
        let chatID = ChatService.directChatID(between: myUID, and: result.id)
        onOpenChat(store.openDirectChat(id: chatID, with: result.id).id)
    }
}
