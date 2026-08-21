import Foundation
import Observation

struct SharedMediaItem: Identifiable {
    let message: Message
    let attachment: Attachment
    var id: String { attachment.id }
}

@MainActor
@Observable
final class ProfileViewModel {
    let userID: String
    private let store: DataStore

    init(userID: String, store: DataStore) {
        self.userID = userID
        self.store = store
    }

    var user: User? { store.user(id: userID) }
    var isSelf: Bool { userID == store.currentUserID }

    var directChat: Chat? {
        store.chats.first { $0.kind == .direct && $0.memberIDs.contains(userID) }
    }

    var isMuted: Bool { directChat?.isMuted ?? false }

    var statusText: String {
        guard let user else { return "" }
        if user.isOnline { return "online" }
        guard store.settings.showLastSeen else { return "" }
        if let lastSeen = user.lastSeen { return lastSeen.lastSeenLabel }
        return "last seen recently"
    }

    var sharedImages: [SharedMediaItem] {
        guard let chat = directChat else { return [] }
        var result: [SharedMediaItem] = []
        for message in store.sortedMessages(for: chat.id) where !message.isDeleted {
            for attachment in message.attachments where attachment.kind == .image {
                result.append(SharedMediaItem(message: message, attachment: attachment))
            }
        }
        return Array(result.reversed())
    }

    @discardableResult
    func openChat() -> String {
        store.createDirectChat(with: userID).id
    }

    func toggleMute() {
        guard var chat = directChat else { return }
        chat.isMuted.toggle()
        store.updateChat(chat)
    }
}
