import Foundation

// Repository abstractions so the local backend can be swapped for a remote
// one (e.g. RemoteChatRepository) without touching views or view models.

protocol ChatRepository {
    func all() -> [Chat]
    func chat(id: String) -> Chat?
    func upsert(_ chat: Chat)
    func remove(id: String)
}

protocol MessageRepository {
    func messages(in chatID: String) -> [Message]
    func add(_ message: Message)
    func update(_ message: Message)
    func remove(_ message: Message)
}

protocol UserRepository {
    func all() -> [User]
    func user(id: String) -> User?
    func upsert(_ user: User)
}

protocol MediaRepository {
    func saveImage(_ data: Data) -> String
    func fileURL(_ fileName: String) -> URL
    func deleteAll()
}

protocol AuthenticationService {
    var currentUserID: String { get }
    func signInLocally()
}

protocol PresenceService {
    func start()
    func stop()
}

// MARK: - Local implementations backed by DataStore / MediaService

extension DataStore: ChatRepository {
    func all() -> [Chat] { chats }

    func upsert(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        } else {
            chats.append(chat)
        }
        save()
    }

    func remove(id: String) {
        deleteChat(id)
    }
}

extension DataStore: MessageRepository {
    func messages(in chatID: String) -> [Message] {
        sortedMessages(for: chatID)
    }

    func add(_ message: Message) {
        addMessage(message)
    }

    func update(_ message: Message) {
        updateMessage(message)
    }

    func remove(_ message: Message) {
        deleteMessage(message)
    }
}

extension DataStore: UserRepository {
    func all() -> [User] { Array(users.values) }

    func upsert(_ user: User) {
        users[user.id] = user
        save()
    }
}

extension DataStore: AuthenticationService {
    func signInLocally() {
        // The prototype is always signed in as the demo user.
    }
}

extension MediaService: MediaRepository {
    func saveImage(_ data: Data) -> String {
        MediaService.save(data, extension: "jpg")
    }

    func fileURL(_ fileName: String) -> URL {
        MediaService.url(for: fileName)
    }
}

@MainActor
final class LocalPresenceService: PresenceService {
    private let store: DataStore

    init(store: DataStore) {
        self.store = store
    }

    func start() {
        PresenceSimulator.start(store: store)
    }

    func stop() {
        PresenceSimulator.stop()
    }
}
