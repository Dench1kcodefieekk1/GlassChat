import SwiftUI

struct ContactsListView: View {
    @Environment(DataStore.self) private var store
    @State private var model = ContactsViewModel()

    var body: some View {
        @Bindable var model = model
        Group {
            if store.users.count <= 1 {
                ContentUnavailableView("No contacts", systemImage: "person.2")
            } else if model.contacts(in: store).isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            } else {
                List {
                    ForEach(model.groups(in: store), id: \.letter) { group in
                        Section(group.letter) {
                            ForEach(group.users) { user in
                                NavigationLink(value: AppRoute.profile(user.id)) {
                                    contactRow(for: user)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Contacts")
        .searchable(text: $model.searchText, prompt: "Search contacts")
    }

    private func contactRow(for user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(title: user.name, seed: user.id, size: 46, isOnline: user.isOnline)
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
                Text(status(for: user))
                    .font(.subheadline)
                    .foregroundStyle(user.isOnline ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .padding(.vertical, 3)
    }

    private func status(for user: User) -> String {
        if user.isOnline { return "online" }
        guard store.settings.showLastSeen else { return "" }
        if let lastSeen = user.lastSeen { return lastSeen.lastSeenLabel }
        return "last seen recently"
    }
}
