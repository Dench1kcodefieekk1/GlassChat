import SwiftUI

struct ComposeView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    let onSelect: (String) -> Void

    private var contacts: [User] {
        let query = searchText.trimmed.lowercased()
        var users = store.users.values.filter { $0.id != store.currentUserID }
        if !query.isEmpty {
            users = users.filter {
                $0.name.lowercased().contains(query) || $0.username.lowercased().contains(query)
            }
        }
        return users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List(contacts) { user in
                Button {
                    onSelect(user.id)
                } label: {
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
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if contacts.isEmpty {
                    ContentUnavailableView(
                        "No contacts found",
                        systemImage: "person.crop.circle.badge.questionmark"
                    )
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
