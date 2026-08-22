import Foundation
import Observation

/// Owns the delayed verification completion so the randomized 5–12 s timer
/// survives leaving the Verification chat: the task is held by this app-wide
/// service, not by the per-chat view model (which tears down on exit).
@MainActor
@Observable
final class VerificationManager {
    static let shared = VerificationManager()

    /// ID of the pill message just appended — observed by the active ChatView
    /// to fire the confetti burst from the pill's frame.
    private(set) var pendingPillID: String?
    private(set) var celebrationChatID: String?

    private var task: Task<Void, Never>?
    private let delay: () -> Double

    /// Injectable delay for unit tests.
    init(delay: @escaping () -> Double = { Double.random(in: 5...12) }) {
        self.delay = delay
    }

    func scheduleCompletion(in store: DataStore, chatID: String) {
        task?.cancel()
        pendingPillID = nil
        celebrationChatID = nil

        task = Task { [weak store] in
            let seconds = delay()
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let store else { return }

            // Global state flip: verified everywhere, persisted to disk.
            var user = store.currentUser
            user.isVerified = true
            store.users[user.id] = user
            store.save()

            var pill = Message(
                id: "msg-\(UUID().uuidString)",
                chatID: chatID,
                senderID: User.verificationBotID,
                text: "Ваш аккаунт верифицирован",
                createdAt: Date(),
                status: .read
            )
            pill.isSystemPill = true
            store.addMessage(pill)

            celebrationChatID = chatID
            pendingPillID = pill.id
        }
    }
}
