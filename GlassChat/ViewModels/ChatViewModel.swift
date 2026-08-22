import SwiftUI
import UIKit
import PhotosUI
import AVFoundation
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
    let verificationEngine = VerificationBotEngine()

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
    var showAttachmentSheet = false
    var cameraUnavailableAlert = false
    var recordingDenied = false
    var scrollTrigger = 0
    var sendScrollTrigger = 0
    var isNearBottom = true
    var pendingIncoming = 0
    var showConfetti = false
    var celebrationMessageID: String? = nil
    var pillFrame: CGRect? = nil

    private var firstUnreadID: String?
    private var unreadCaptured = false
    private var replyTask: Task<Void, Never>?
    private var confettiTask: Task<Void, Never>?

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
    var isVerificationChat: Bool {
        chat?.memberIDs.contains(User.verificationBotID) == true
    }

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
        confettiTask?.cancel()
        confettiTask = nil
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
            duration: Self.probedAudioDuration(for: fileName, extension: ext),
            displayName: url.lastPathComponent,
            fileSize: Int64(data.count)
        )]
        store.addMessage(message)
        scrollTrigger += 1
        sendScrollTrigger += 1
        simulateDeliveryAndReply(for: message)
    }

    /// Reads the real duration of picked audio files (`.mp3`, `.m4a`, …) so
    /// bubbles and the profile music list can display it immediately.
    private static func probedAudioDuration(for fileName: String, extension ext: String) -> TimeInterval? {
        let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "caf"]
        guard audioExtensions.contains(ext) else { return nil }
        return (try? AVAudioPlayer(contentsOf: MediaService.url(for: fileName)))?.duration
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

    // MARK: - Verification bot

    /// Handles a tap on an inline keyboard button attached to a bot message.
    /// Telegram-style: the tapped keyboard is removed before the bot replies.
    func tapInlineButton(_ button: InlineButton, on message: Message) {
        guard !message.isDeleted else { return }
        Haptics.light()
        var updated = message
        updated.inlineButtons = nil
        store.updateMessage(updated)

        runBot(text: nil, buttonAction: button.action)
    }

    private func runBot(text: String?, buttonAction: String?) {
        replyTask?.cancel()
        replyTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self, !Task.isCancelled else { return }
            let reaction: VerificationBotEngine.Reaction
            if let buttonAction {
                reaction = self.verificationEngine.handleButton(action: buttonAction)
            } else if let text {
                reaction = self.verificationEngine.handle(command: text)
            } else {
                return
            }
            for message in reaction.messages {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                self.store.addMessage(self.botMessage(message))
                self.scrollTrigger += 1
            }
            if reaction.verified {
                // The delayed completion lives in the shared VerificationManager
                // so leaving this chat never cancels the 5–12 s timer.
                VerificationManager.shared.scheduleCompletion(in: self.store, chatID: self.chatID)
            }
        }
    }

    private func botMessage(_ reply: VerificationBotEngine.BotMessage) -> Message {
        var message = Message(
            id: "msg-\(UUID().uuidString)",
            chatID: chatID,
            senderID: User.verificationBotID,
            text: reply.text,
            createdAt: Date(),
            status: .read
        )
        message.inlineButtons = reply.buttons
        return message
    }

    /// Fired when the shared VerificationManager appends the gift pill while
    /// this chat is on screen: scrolls to it and bursts confetti from its frame.
    func triggerConfetti(for messageID: String) {
        celebrationMessageID = messageID
        pillFrame = nil
        scrollTrigger += 1
        showConfetti = true

        confettiTask?.cancel()
        confettiTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.5))
            self?.showConfetti = false
        }
    }

    /// Global frame of the gift pill row; anchors the confetti burst.
    func reportCelebrationPillFrame(_ rect: CGRect) {
        pillFrame = rect
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

            // The Verification bot answers instead of the canned simulator.
            if self.isVerificationChat {
                self.runBot(text: message.text, buttonAction: nil)
                return
            }

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
