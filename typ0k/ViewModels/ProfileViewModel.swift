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

    /// Fetched `users/{userID}` document for counterparts that only exist
    /// in Firestore (no local `User` record).
    private(set) var remoteProfile: RemoteUserProfile?
    private(set) var isLoadingRemote = false
    /// Session key of the last fetch — an account switch invalidates the
    /// cache so stale UID references never survive the swap.
    private var fetchedForSession: String?

    init(userID: String, store: DataStore) {
        self.userID = userID
        self.store = store
    }

    /// Local record first; Firestore-only counterparts resolve from the
    /// fetched `users/{userID}` document instead of failing the screen.
    var user: User? {
        if let local = store.user(id: userID) { return local }
        guard let remote = remoteProfile else { return nil }
        let name = remote.displayName.isEmpty
            ? (remote.username.isEmpty ? "User" : "@\(remote.username)")
            : remote.displayName
        return User(
            id: userID,
            name: name,
            username: remote.username.isEmpty ? userID : remote.username,
            bio: remote.bio,
            phone: ""
        )
    }

    /// True while the Firestore lookup is in flight and nothing resolved yet.
    var isLoading: Bool { isLoadingRemote && user == nil }

    /// Account-switch aware: `userID` may be the Firebase UID of the
    /// signed-in account itself (self-profile via chat header).
    var isSelf: Bool {
        userID == store.currentUserID || userID == AuthManager.shared.currentUID
    }

    /// Fetches `users/{userID}` when no local record exists. Keyed by the
    /// active Firebase session so switching accounts clears and re-runs the
    /// lookup instead of reusing the previous account's cached state.
    func loadIfNeeded() {
        guard store.user(id: userID) == nil else { return }
        let sessionKey = AuthManager.shared.currentUID ?? "local"
        guard fetchedForSession != sessionKey else { return }
        fetchedForSession = sessionKey
        remoteProfile = nil
        isLoadingRemote = true
        Task { [userID] in
            let profile = await ChatService.shared.fetchUserProfile(uid: userID)
            guard !Task.isCancelled else { return }
            remoteProfile = profile
            isLoadingRemote = false
        }
    }

    /// Drops all cached remote state — called when the active account
    /// changes while this screen is somehow still alive.
    func resetForAccountSwitch() {
        remoteProfile = nil
        fetchedForSession = nil
        loadIfNeeded()
    }

    var directChat: Chat? {
        store.chats.first { $0.kind == .direct && $0.memberIDs.contains(userID) }
    }

    var isMuted: Bool { directChat?.isMuted ?? false }

    var statusText: String {
        // Live Firestore presence wins for remote counterparts.
        if let presence = PresenceService.shared.observedPresence {
            switch presence.lastSeenPrivacy {
            case .nobody:
                return "last seen recently"
            case .everyone, .myContacts:
                if presence.isOnline { return "online" }
                if let lastSeen = presence.lastSeen { return lastSeen.lastSeenLabel }
                return "last seen recently"
            }
        }
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
        // Firestore-backed counterpart: route through the deterministic
        // `min(uid)_max(uid)` chat ID so both sides resolve the same thread.
        if store.user(id: userID) == nil,
           !isSelf,
           let myUID = AuthManager.shared.currentUID {
            let chatID = ChatService.directChatID(between: myUID, and: userID)
            return store.openDirectChat(id: chatID, with: userID).id
        }
        return store.createDirectChat(with: userID).id
    }

    func toggleMute() {
        guard var chat = directChat else { return }
        chat.isMuted.toggle()
        store.updateChat(chat)
    }
}
