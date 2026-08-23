import Foundation
import Observation

@MainActor
@Observable
final class ChatsViewModel {
    var searchText = ""
    var path: [AppRoute] = []
    var showCompose = false

    /// Account-scoped chat list: local chats are filtered to the active user
    /// and merged with the live Firestore chats — the snapshot listener is
    /// already restricted to `participants arrayContains <currentUID>`, so
    /// one account can never see another account's dialogs.
    func visibleChats(in store: DataStore) -> [Chat] {
        let query = searchText.trimmed.lowercased()

        var byID: [String: Chat] = [:]
        for chat in store.chats where chat.memberIDs.contains(store.currentUserID) {
            byID[chat.id] = chat
        }

        let uid = AuthManager.shared.currentUID ?? ""
        for remote in ChatService.shared.remoteChats {
            var chat = byID[remote.id] ?? Chat(
                id: remote.id,
                kind: .direct,
                title: title(for: remote, in: store),
                memberIDs: remote.participants
            )
            if !remote.lastMessage.isEmpty {
                chat.lastMessagePreview = remote.lastMessage
            }
            if let timestamp = remote.lastMessageTimestamp {
                chat.lastMessageAt = timestamp
            }
            chat.unreadCount = remote.unreadCount[uid] ?? 0
            byID[remote.id] = chat
        }

        var filtered = Array(byID.values)
        if !query.isEmpty {
            filtered = filtered.filter { $0.title.lowercased().contains(query) }
        }
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            let lhsDate = lhs.lastMessageAt ?? .distantPast
            let rhsDate = rhs.lastMessageAt ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    /// Resolves a remote chat's title from the counterpart's local profile.
    private func title(for remote: RemoteChat, in store: DataStore) -> String {
        let uid = AuthManager.shared.currentUID ?? ""
        let otherID = remote.participants.first { $0 != uid }
        return otherID.flatMap { store.users[$0]?.name } ?? "Chat"
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
