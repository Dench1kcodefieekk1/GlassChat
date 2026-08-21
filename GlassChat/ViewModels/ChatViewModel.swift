import SwiftUI
import UIKit
import PhotosUI
import Observation

enum ChatRowKind {
    case day(String)
    case unreadSeparator
    case message(Message)
    case typing
}

struct ChatRowItem: Identifiable {
    let id: String
    let kind: ChatRowKind
}

struct PendingImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ViewerItem: Identifiable {
    let fileName: String
    var id: String { fileName }
}

@MainActor
@Observable
final class ChatViewModel {
    let chatID: String
    private let store: DataStore

    let recorder = AudioRecorderService()
    let playback = AudioPlaybackService()

    var draft = ""
    var replyTo: Message?
    var editingMessage: Message?
    var forwardMessage: Message?
    var pendingImage: PendingImage?
    var viewerItem: ViewerItem?
    var pickerItem: PhotosPickerItem?
    var showPhotoPicker = false
    var showCamera = false
    var showFilePicker = false
    var cameraUnavailableAlert = false
    var recordingDenied = false
    var scrollTrigger = 0
    var sendScrollTrigger = 0
    var isNearBottom = true
    var pendingIncoming = 0

    private var firstUnreadID: String?
    private var unreadCaptured = false
    private var replyTask: Task<Void, Never>?

    static let cannedReplies = [
        "Sounds good!",
        "Haha, exactly 😄",
        "Let me check and get back to you.",
        "Perfect, thanks!",
        "Can you send more details?",
        "I'm in 👍",
        "Interesting… tell me more.",
        "Give me 5 minutes.",
        "That works for me!",
        "Awesome 🔥"
    ]

    init(chatID: String, store: DataStore) {
        self.chatID = chatID
        self.store = store
    }

    // MARK: - Derived state

    var chat: Chat? { store.chat(id: chatID) }
    var title: String { chat?.title ?? "" }
    var isGroup: Bool { chat?.kind == .group }
    var otherUser: User? { chat.flatMap { store.otherUser(in: $0) } }
    var isTyping: Bool { store.typingChatIDs.contains(chatID) }
    var isCameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var subtitle: String {
        if isTyping { return "typing…" }
        if isGroup { return "\(chat?.memberIDs.count ?? 0) members" }
        guard let user = otherUser else { return "" }
        if user.isOnline { return "online" }
        guard store.settings.showLastSeen else { return "" }
        if let lastSeen = user.lastSeen { return lastSeen.lastSeenLabel }
        return "last seen recently"
    }

    var profileUserID: String? {
        otherUser?.id
    }

    func rows() -> [ChatRowItem] {
        var items: [ChatRowItem] = []
        var lastDay = ""
        for message in store.sortedMessages(for: chatID) {
            let day = message.createdAt.daySeparatorLabel
            if day != lastDay {
                lastDay = day
                items.append(ChatRowItem(id: "day-\(day)-\(items.count)", kind: .day(day)))
            }
            if let firstUnreadID, firstUnreadID == message.id {
                items.append(ChatRowItem(id: "unread-separator", kind: .unreadSeparator))
            }
            items.append(ChatRowItem(id: message.id, kind: .message(message)))
        }
        if isTyping {
            items.append(ChatRowItem(id: "typing-indicator", kind: .typing))
        }
        return items
    }

    func replyPreview(for message: Message) -> Message? {
        guard let replyID = message.replyToID else { return nil }
        return store.message(id: replyID, in: chatID)
    }

    // MARK: - Lifecycle

    func activate() {
        store.activeChatID = chatID
        if !unreadCaptured {
            unreadCaptured = true
            if let chat, chat.unreadCount > 0 {
                let messages = store.sortedMessages(for: chatID)
                firstUnreadID = messages.suffix(chat.unreadCount).first?.id
            }
        }
        store.markAllRead(chatID)
    }

    func deactivate() {
        playback.stop()
        replyTask?.cancel()
        replyTask = nil
        store.setTyping(chatID, false)
        if store.activeChatID == chatID {
            store.activeChatID = nil
        }
    }

    func markReadIfActive() {
        if store.activeChatID == chatID {
            store.markAllRead(chatID)
        }
    }

    // MARK: - Sending

    func send() {
        if let editing = editingMessage {
            applyEdit(editing, draft)
            return
        }
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        var message = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: chatID,
            senderID: store.currentUserID,
            text: text,
            createdAt: Date()
        )
        message.replyToID = replyTo?.id
        draft = ""
        replyTo = nil
        store.addMessage(message)
        scrollTrigger += 1
        sendScrollTrigger += 1
        simulateDeliveryAndReply(for: message)
    }

    func sendImage(_ pending: PendingImage, caption: String) {
        let scaled = MediaService.downscale(pending.image)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return }
        let fileName = MediaService.save(data, extension: "jpg")
        var message = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: chatID,
            senderID: store.currentUserID,
            text: caption.trimmed,
            createdAt: Date()
        )
        message.attachments = [Attachment(id: "att-\(UUID().uuidString)", kind: .image, fileName: fileName)]
        message.replyToID = replyTo?.id
        pendingImage = nil
        replyTo = nil
        store.addMessage(message)
        scrollTrigger += 1
        sendScrollTrigger += 1
        simulateDeliveryAndReply(for: message)
    }

    func openCamera() {
        if isCameraAvailable {
            showCamera = true
        } else {
            cameraUnavailableAlert = true
        }
    }

    func attachFile(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url) else { return }
        let ext = url.pathExtension.isEmpty ? "dat" : url.pathExtension.lowercased()
        let fileName = MediaService.save(data, extension: ext)
        var message = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: chatID,
            senderID: store.currentUserID,
            text: "",
            createdAt: Date()
        )
        message.attachments = [Attachment(
            id: "att-\(UUID().uuidString)",
            kind: .file,
            fileName: fileName,
            displayName: url.lastPathComponent,
            fileSize: Int64(data.count)
        )]
        store.addMessage(message)
        scrollTrigger += 1
        sendScrollTrigger += 1
        simulateDeliveryAndReply(for: message)
    }

    // MARK: - Voice

    func startRecording() {
        Task {
            let started = await recorder.start()
            if !started {
                recordingDenied = true
            }
        }
    }

    func cancelRecording() {
        recorder.cancel()
    }

    func sendRecording() {
        guard let result = recorder.stop() else { return }
        let fileName = MediaService.move(from: result.url, extension: "m4a")
        var message = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: chatID,
            senderID: store.currentUserID,
            text: "",
            createdAt: Date()
        )
        message.attachments = [Attachment(
            id: "att-\(UUID().uuidString)",
            kind: .voice,
            fileName: fileName,
            duration: result.duration,
            waveform: result.waveform
        )]
        store.addMessage(message)
        scrollTrigger += 1
        sendScrollTrigger += 1
        simulateDeliveryAndReply(for: message)
    }

    // MARK: - Message actions

    func toggleReaction(_ emoji: String, on message: Message) {
        var updated = message
        var reactors = updated.reactions[emoji] ?? []
        if reactors.contains(store.currentUserID) {
            reactors.removeAll { $0 == store.currentUserID }
        } else {
            reactors.append(store.currentUserID)
        }
        updated.reactions[emoji] = reactors.isEmpty ? nil : reactors
        store.updateMessage(updated)
    }

    func applyEdit(_ message: Message, _ newText: String) {
        let text = newText.trimmed
        guard !text.isEmpty else { return }
        var updated = message
        updated.text = text
        updated.isEdited = true
        store.updateMessage(updated)
        editingMessage = nil
        draft = ""
    }

    func cancelEditing() {
        editingMessage = nil
        draft = ""
    }

    func delete(_ message: Message) {
        store.deleteMessage(message)
    }

    func forward(_ message: Message, to targetChatID: String) {
        guard targetChatID != chatID else { return }
        var copy = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: targetChatID,
            senderID: store.currentUserID,
            text: message.text,
            createdAt: Date()
        )
        copy.attachments = message.attachments
        copy.forwardedFrom = store.displayName(of: message)
        store.addMessage(copy)
    }

    // MARK: - Simulation

    private func simulateDeliveryAndReply(for message: Message) {
        replyTask?.cancel()
        replyTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            var updated = message
            updated.status = .sent
            self.store.updateMessage(updated)

            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            updated.status = .delivered
            self.store.updateMessage(updated)

            guard let chat = self.chat, chat.kind == .direct else { return }

            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self.store.setTyping(self.chatID, true)
            try? await Task.sleep(for: .seconds(Double.random(in: 1.0...2.0)))
            self.store.setTyping(self.chatID, false)
            guard !Task.isCancelled else { return }

            self.markOwnMessagesRead()

            let replyText = Self.cannedReplies[Int.random(in: 0..<Self.cannedReplies.count)]
            let senderID = chat.memberIDs.first { $0 != self.store.currentUserID } ?? self.store.currentUserID
            let reply = Message(
                id: "msg-\(UUID().uuidString)",
                chatID: self.chatID,
                senderID: senderID,
                text: replyText,
                createdAt: Date(),
                status: .read
            )
            self.store.addMessage(reply)
            self.scrollTrigger += 1

            if self.store.activeChatID != self.chatID, !chat.isMuted, self.store.settings.notifyMessages {
                NotificationService.shared.postIncoming(
                    chatTitle: chat.title,
                    text: replyText,
                    settings: self.store.settings
                )
            }
        }
    }

    private func markOwnMessagesRead() {
        guard store.settings.readReceipts else { return }
        for message in store.sortedMessages(for: chatID) where message.senderID == store.currentUserID && message.status != .read {
            var updated = message
            updated.status = .read
            store.updateMessage(updated)
        }
    }
}
