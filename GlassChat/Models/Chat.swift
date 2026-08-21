import Foundation

enum ChatKind: String, Codable {
    case direct
    case group
}

struct Chat: Identifiable, Codable, Hashable {
    var id: String
    var kind: ChatKind
    var title: String
    var memberIDs: [String]
    var isPinned: Bool = false
    var isMuted: Bool = false
    var unreadCount: Int = 0
    var lastMessageAt: Date? = nil
    var lastMessagePreview: String = ""
}
