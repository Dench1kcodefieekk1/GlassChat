import Foundation
import Observation
import SwiftUI

struct Snapshot: Codable {
    var currentUserID: String
    var users: [User]
    var chats: [Chat]
    var messages: [Message]
    var settings: AppSettings
}

extension JSONEncoder {
    static let iso8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

@MainActor
@Observable
final class DataStore {
    var currentUserID: String
    var users: [String: User]
    var chats: [Chat]
    var messages: [String: [Message]]
    var settings: AppSettings
    var typingChatIDs: Set<String> = []
    var activeChatID: String? = nil

    private static var fileURL: URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GlassChat", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("database.json")
    }

    init(snapshot: Snapshot) {
        currentUserID = snapshot.currentUserID
        users = Dictionary(uniqueKeysWithValues: snapshot.users.map { ($0.id, $0) })
        chats = snapshot.chats
        var grouped: [String: [Message]] = [:]
        for message in snapshot.messages {
            grouped[message.chatID, default: []].append(message)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.createdAt < $1.createdAt }
        }
        messages = grouped
        settings = snapshot.settings
    }

    static func load() -> DataStore {
        let store: DataStore
        if let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder.iso8601.decode(Snapshot.self, from: data) {
            store = DataStore(snapshot: snapshot)
        } else {
            store = DataStore(snapshot: DemoSeeder.makeSnapshot())
            store.save()
        }
        // Existing installs persisted before the bot existed still get it.
        store.ensureVerificationBot()
        return store
    }

    /// Idempotently creates the system Verification bot, its chat, and the
    /// intro message so both fresh and upgraded installs see the flow.
    func ensureVerificationBot() {
        let botChatID = "chat-verification"
        var changed = false

        if users[User.verificationBotID] == nil {
            let bot = User(
                id: User.verificationBotID,
                name: "Verification",
                username: "verification",
                bio: "Official verification bot.",
                phone: "",
                isVerified: true
            )
            users[bot.id] = bot
            changed = true
        }

        if !chats.contains(where: { $0.kind == .direct && $0.memberIDs.contains(User.verificationBotID) }) {
            chats.append(Chat(
                id: botChatID,
                kind: .direct,
                title: "Verification",
                memberIDs: [currentUserID, User.verificationBotID]
            ))
            changed = true
        }

        if messages[botChatID, default: []].isEmpty {
            messages[botChatID] = [
                Message(
                    id: "msg-bot-intro",
                    chatID: botChatID,
                    senderID: User.verificationBotID,
                    text: "Добро пожаловать! Отправьте /start, чтобы пройти верификацию и получить галочку рядом с именем.",
                    createdAt: Date(),
                    status: .read
                )
            ]
            changed = true
        }

        if changed {
            save()
        }
    }

    func save() {
        let snapshot = Snapshot(
            currentUserID: currentUserID,
            users: Array(users.values),
            chats: chats,
            messages: Array(messages.values).flatMap { $0 },
            settings: settings
        )
        if let data = try? JSONEncoder.iso8601.encode(snapshot) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    // MARK: - Lookups

    func chat(id: String) -> Chat? {
        chats.first { $0.id == id }
    }

    func user(id: String) -> User? {
        users[id]
    }

    var currentUser: User {
        users[currentUserID] ?? User(id: currentUserID, name: "Alex", username: "alex", bio: "", phone: "")
    }

    func otherUser(in chat: Chat) -> User? {
        guard chat.kind == .direct else { return nil }
        return chat.memberIDs
            .first { $0 != currentUserID }
            .flatMap { users[$0] }
    }

    func sortedMessages(for chatID: String) -> [Message] {
        messages[chatID] ?? []
    }

    func lastMessage(for chatID: String) -> Message? {
        messages[chatID]?.last
    }

    func message(id: String, in chatID: String) -> Message? {
        messages[chatID]?.first { $0.id == id }
    }

    func displayName(of message: Message) -> String {
        users[message.senderID]?.name ?? "Unknown"
    }

    func firstName(of message: Message) -> String {
        let name = displayName(of: message)
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    var totalUnread: Int {
        chats.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Mutations

    func updateChat(_ chat: Chat) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index] = chat
        save()
    }

    func togglePin(_ chat: Chat) {
        var updated = chat
        updated.isPinned.toggle()
        updateChat(updated)
    }

    func toggleMute(_ chat: Chat) {
        var updated = chat
        updated.isMuted.toggle()
        updateChat(updated)
    }

    func markAllRead(_ chatID: String) {
        guard var chat = chat(id: chatID), chat.unreadCount != 0 else { return }
        chat.unreadCount = 0
        updateChat(chat)
    }

    func setTyping(_ chatID: String, _ isTyping: Bool) {
        if isTyping {
            typingChatIDs.insert(chatID)
        } else {
            typingChatIDs.remove(chatID)
        }
    }

    func addMessage(_ message: Message) {
        var list = messages[message.chatID] ?? []
        list.append(message)
        messages[message.chatID] = list

        var targetTitle: String?
        if var chat = chat(id: message.chatID) {
            chat.lastMessageAt = message.createdAt
            chat.lastMessagePreview = MessagePreview.text(for: message, in: self)
            if activeChatID == message.chatID {
                chat.unreadCount = 0
            } else if message.senderID != currentUserID {
                chat.unreadCount += 1
            }
            updateChat(chat)
            targetTitle = chat.title
        } else {
            save()
        }

        // Floating in-app banner for messages the user isn't reading right now.
        if message.senderID != currentUserID, activeChatID != message.chatID {
            InAppNotificationCenter.shared.show(
                chatID: message.chatID,
                title: targetTitle ?? users[message.senderID]?.name ?? "New message",
                text: message.text.isEmpty ? "Attachment" : message.text
            )
        }
    }

    func updateMessage(_ message: Message) {
        guard var list = messages[message.chatID],
              let index = list.firstIndex(where: { $0.id == message.id }) else { return }
        list[index] = message
        messages[message.chatID] = list

        if let last = list.last, last.id == message.id, var chat = chat(id: message.chatID) {
            chat.lastMessagePreview = MessagePreview.text(for: message, in: self)
            updateChat(chat)
        } else {
            save()
        }
    }

    func deleteMessage(_ message: Message) {
        guard var list = messages[message.chatID] else { return }
        list.removeAll { $0.id == message.id }
        messages[message.chatID] = list
        for attachment in message.attachments {
            MediaService.delete(attachment.fileName)
        }
        if var chat = chat(id: message.chatID) {
            if let last = list.last {
                chat.lastMessagePreview = MessagePreview.text(for: last, in: self)
                chat.lastMessageAt = last.createdAt
            } else {
                chat.lastMessagePreview = ""
                chat.lastMessageAt = nil
            }
            updateChat(chat)
        } else {
            save()
        }
    }

    func deleteChat(_ chatID: String) {
        for message in messages[chatID] ?? [] {
            for attachment in message.attachments {
                MediaService.delete(attachment.fileName)
            }
        }
        messages[chatID] = nil
        chats.removeAll { $0.id == chatID }
        save()
    }

    func createDirectChat(with userID: String) -> Chat {
        if let existing = chats.first(where: { $0.kind == .direct && $0.memberIDs.contains(userID) }) {
            return existing
        }
        let chat = Chat(
            id: "chat-\(UUID().uuidString)",
            kind: .direct,
            title: users[userID]?.name ?? "Chat",
            memberIDs: [currentUserID, userID]
        )
        chats.append(chat)
        save()
        return chat
    }

    /// Persists the phone number entered at registration onto the active
    /// session user; the profile binds directly to `currentUser.phone`.
    func updateCurrentUserPhone(_ number: String) {
        guard var user = users[currentUserID] else { return }
        user.phone = number
        users[currentUserID] = user
        save()
    }

    // MARK: - Search

    func searchMessages(_ query: String, limit: Int = 20) -> [Message] {
        let needle = query.lowercased()
        guard needle.count >= 2 else { return [] }
        var matches: [Message] = []
        for chat in chats {
            for message in messages[chat.id] ?? [] where !message.isDeleted {
                if message.text.lowercased().contains(needle) {
                    matches.append(message)
                }
            }
        }
        return Array(matches.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
}

enum MessagePreview {
    static func text(for message: Message, in store: DataStore) -> String {
        if message.isDeleted { return "Deleted message" }
        if let attachment = message.attachments.first {
            switch attachment.kind {
            case .image:
                return message.text.isEmpty ? "Photo" : "Photo · \(message.text)"
            case .voice:
                return "Voice message"
            case .file:
                return attachment.displayName ?? "File"
            }
        }
        return message.text
    }
}

extension View {
    /// Persists settings whenever any settings value changes on screen.
    func autosaveSettings(_ store: DataStore) -> some View {
        onChange(of: store.settings) {
            store.save()
        }
    }
}
