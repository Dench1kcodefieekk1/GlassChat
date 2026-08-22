import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

/// Telegram-style inline keyboard button attached to bot messages.
struct InlineButton: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let action: String
}

struct Message: Identifiable, Codable, Hashable {
    var id: String
    var chatID: String
    var senderID: String
    var text: String
    var attachments: [Attachment] = []
    var createdAt: Date
    var status: MessageStatus = .sending
    var isEdited: Bool = false
    var isDeleted: Bool = false
    var replyToID: String? = nil
    var forwardedFrom: String? = nil
    var reactions: [String: [String]] = [:]
    var inlineButtons: [InlineButton]? = nil
    /// Centered Telegram-gift-style system pill (e.g. "Ваш аккаунт верифицирован").
    var isSystemPill: Bool = false
}

extension Message {
    var isOutgoingTextEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
