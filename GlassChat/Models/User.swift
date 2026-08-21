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

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    static let currentID = "user-me"
}
