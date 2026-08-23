import Foundation
import Observation

@MainActor
@Observable
final class ChatsViewModel {
    var searchText = ""
    var path: [AppRoute] = []
    var showCompose = false

    func visibleChats(in store: DataStore) -> [Chat] {
        let query = searchText.trimmed.lowercased()
        let filtered: [Chat]
        if query.isEmpty {
            filtered = store.chats
        } else {
            filtered = store.chats.filter { chat in
                chat.title.lowercased().contains(query)
            }
        }
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            let lhsDate = lhs.lastMessageAt ?? .distantPast
            let rhsDate = rhs.lastMessageAt ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    func messageMatches(in store: DataStore) -> [Message] {
        store.searchMessages(searchText.trimmed)
    }

    func openChat(_ chatID: String) {
        path.append(.chat(chatID))
    }

    func popToChat(_ chatID: String) {
        if let index = path.firstIndex(of: .chat(chatID)) {
            path.removeSubrange((index + 1)...)
        } else {
            path.append(.chat(chatID))
        }
    }
}
