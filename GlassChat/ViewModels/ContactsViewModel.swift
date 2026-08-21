import Foundation
import Observation

@MainActor
@Observable
final class ContactsViewModel {
    var searchText = ""

    func contacts(in store: DataStore) -> [User] {
        let query = searchText.trimmed.lowercased()
        var users = store.users.values.filter { $0.id != store.currentUserID }
        if !query.isEmpty {
            users = users.filter {
                $0.name.lowercased().contains(query) || $0.username.lowercased().contains(query)
            }
        }
        return users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func groups(in store: DataStore) -> [(letter: String, users: [User])] {
        let grouped = Dictionary(grouping: contacts(in: store)) { user -> String in
            let first = user.name.prefix(1).uppercased()
            return first.isEmpty ? "#" : first
        }
        return grouped
            .map { (letter: $0.key, users: $0.value) }
            .sorted { $0.letter < $1.letter }
    }
}
