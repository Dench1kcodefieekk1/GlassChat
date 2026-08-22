import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var username: String
    var bio: String
    var phone: String
    var isVerified: Bool = false
    var isOnline: Bool = false
    var lastSeen: Date? = nil

    // Profile V2 (all optional so previously persisted snapshots keep decoding)
    var avatarFileName: String? = nil
    var registeredAt: Date? = nil
    var personalAccent: AccentChoice? = nil
    var linkedChannel: String? = nil

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    static let currentID = "user-me"
}
