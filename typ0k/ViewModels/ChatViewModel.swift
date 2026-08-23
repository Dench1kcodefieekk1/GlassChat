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

    init(chatID: String, store: DataStore) {
        self.chatID = chatID
        self.store = store
    }

    // MARK: - Derived state

    var chat: Chat? { store.chat(id: chatID) }
    var isGroup: Bool { chat?.kind == .group }
    var otherUser: User? { chat.flatMap { store.otherUser(in: $0) } }

    /// Firestore profile of the counterpart, fetched on open when the chat
    /// exists only remotely (no local `Chat` record).
    var remoteProfile: RemoteUserProfile?
    private var profileFetchStarted = false

    /// The counterpart's Firebase UID for deterministic `uid1_uid2` chats.
    var counterpartUID: String? {
        guard chatID.contains("_"), let uid = AuthManager.shared.currentUID else { return nil }
        let parts = chatID.components(separatedBy: "_")
        guard parts.count == 2, parts.contains(uid) else { return nil }
        return parts.first { $0 != uid }
    }

    /// Header title with fallbacks: local chat title → Firestore displayName
    /// → @username → local user name/username/phone, never a blank bar.
    var title: String {
        if let chat, !chat.title.isEmpty, chat.title != "Chat" {
            return chat.title
        }
        if let remoteProfile {
            if !remoteProfile.displayName.isEmpty { return remoteProfile.displayName }
            if !remoteProfile.username.isEmpty { return "@\(remoteProfile.username)" }
        }
        if let user = otherUser {
            if !user.name.isEmpty { return user.name }
            if !user.username.isEmpty { return "@\(user.username)" }
            if !user.phone.isEmpty { return user.phone }
        }
        return chat?.title ?? "Chat"
    }

    /// Profile link target: local user first, then the remote counterpart UID.
    var profileUserID: String? {
        otherUser?.id ?? counterpartUID
    }

    var isTyping: Bool { store.typingChatIDs.contains(chatID) }
    var isCameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    var isVerificationChat: Bool {
        chat?.memberIDs.contains(User.verificationBotID) == true
    }
    var isWalletChat: Bool {
        chat?.memberIDs.contains(User.walletBotID) == true
    }
    var isFragmentChat: Bool {
        chat?.memberIDs.contains(User.fragmentBotID) == true
    }
    /// System bots (Verification / Wallet / Fragment) never send canned replies.
    var isSystemBotChat: Bool {
        isVerificationChat || isWalletChat || isFragmentChat
    }

    var subtitle: String {
        if isTyping { return "typing…" }
        if isGroup { return "\(chat?.memberIDs.count ?? 0) members" }
        if let user = otherUser {
            if user.isOnline { return "online" }
            guard store.settings.showLastSeen else { return "" }
            if let lastSeen = user.lastSeen { return lastSeen.lastSeenLabel }
            return "last seen recently"
        }
        if let remoteProfile, !remoteProfile.username.isEmpty {
            return "@\(remoteProfile.username)"
        }
        return ""
    }

    func rows() -> [ChatRowItem] {
        var items: [ChatRowItem] = []
        var lastDay = ""
        for message in mergedMessages() {
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

    /// True for chats addressed by the deterministic `uid1_uid2` ID — those
    /// are backed by Firestore and receive live snapshot updates.
    var isFirestoreChat: Bool { chatID.contains("_") }

    /// Local messages overlaid with the live Firestore snapshot stream.
    /// Both copies of an outgoing message share one ID, so merging dedupes
    /// automatically; incoming messages from the counterpart arrive here in
    /// real time without any manual refresh.
    func mergedMessages() -> [Message] {
        let local = store.sortedMessages(for: chatID)
        guard isFirestoreChat else { return local }
        let remote = ChatService.shared.remoteMessages
        guard !remote.isEmpty else { return local }

        var byID: [String: Message] = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for entry in remote where byID[entry.id] == nil {
            byID[entry.id] = Message(
                id: entry.id,
                chatID: chatID,
                senderID: entry.senderId,
                text: entry.text,
                createdAt: entry.timestamp ?? Date(),
                status: MessageStatus(rawValue: entry.status) ?? .sent
            )
        }
        return byID.values.sorted { $0.createdAt < $1.createdAt }
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
        ChatService.shared.observeMessages(in: chatID)
        Task { await ChatService.shared.markRead(chatID: chatID) }
        fetchRemoteProfileIfNeeded()
    }

    /// One-shot fetch of the counterpart's `users/{uid}` document so the
    /// header shows their display name / @username even for chats that only
    /// exist in Firestore.
    private func fetchRemoteProfileIfNeeded() {
        guard !profileFetchStarted, otherUser == nil, let uid = counterpartUID else { return }
        profileFetchStarted = true
        Task {
            if let profile = await ChatService.shared.fetchUserProfile(uid: uid) {
                remoteProfile = profile
            }
        }
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
        if ChatService.shared.activeChatID == chatID {
            ChatService.shared.stopMessageListener()
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
        UserLevelManager.shared.addXPForMessage(text: text)
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
        Task { await ChatService.shared.mirrorLocalSend(message: message, chatID: chatID) }
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

    // MARK: - Delivery status

    /// Local sending → sent → delivered progression only. Real replies arrive
    /// through the Firestore snapshot listener — there is no simulated
    /// auto-responder for 1-on-1 chats.
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

            // The in-app Verification bot keeps answering in its own chat.
            if self.isVerificationChat {
                self.runBot(text: message.text, buttonAction: nil)
            }
        }
    }
}
