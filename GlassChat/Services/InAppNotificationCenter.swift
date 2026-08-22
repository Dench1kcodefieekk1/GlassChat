import Foundation
import Observation

/// Publishes floating in-app banner notifications for messages arriving in
/// chats the user is not currently reading.
@MainActor
@Observable
final class InAppNotificationCenter {
    struct Banner: Identifiable, Equatable {
        let id = UUID()
        let chatID: String
        let title: String
        let text: String
    }

    static let shared = InAppNotificationCenter()

    private(set) var current: Banner?

    private var hideTask: Task<Void, Never>?
    private let displayDuration: Duration

    init(displayDuration: Duration = .seconds(4)) {
        self.displayDuration = displayDuration
    }

    func show(chatID: String, title: String, text: String) {
        current = Banner(chatID: chatID, title: title, text: text)
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.displayDuration)
            guard !Task.isCancelled else { return }
            self.dismiss()
        }
    }

    func dismiss() {
        hideTask?.cancel()
        hideTask = nil
        current = nil
    }
}
