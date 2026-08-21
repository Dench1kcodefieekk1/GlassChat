import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
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
}

extension Message {
    var isOutgoingTextEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
