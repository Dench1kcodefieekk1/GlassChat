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

    // Profile V2 (optional so previously persisted snapshots keep decoding)
    var avatarFileName: String? = nil
    /// Falls back dynamically to the account creation date when missing.
    var registeredAt: Date = Date()
    var personalAccent: AccentChoice? = nil
    var linkedChannel: String? = nil
    var bannerFileName: String? = nil
    /// Equipped Discord-style avatar decoration (see `AvatarFrameManager`).
    var selectedFrameId: String? = nil

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    /// Registration date formatted as "MMMM yyyy" (e.g. "October 2023").
    var registrationDateLabel: String {
        registeredAt.formatted(.dateTime.month(.wide).year())
    }

    static let currentID = "user-me"
    /// System bot that owns the in-app verification flow.
    static let verificationBotID = "user-verification"
    /// System bot that owns the Wallet mini app.
    static let walletBotID = "user-wallet"
    /// System bot that owns the Fragment username market mini app.
    static let fragmentBotID = "user-fragment"
}

// MARK: - Backward-compatible decoding

extension User {
    private enum CodingKeys: String, CodingKey {
        case id, name, username, bio, phone, isVerified, isOnline, lastSeen
        case avatarFileName, registeredAt, personalAccent, linkedChannel, bannerFileName, selectedFrameId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
        lastSeen = try container.decodeIfPresent(Date.self, forKey: .lastSeen)
        avatarFileName = try container.decodeIfPresent(String.self, forKey: .avatarFileName)
        // Snapshots persisted before this field existed decode to the
        // account creation date dynamically.
        registeredAt = try container.decodeIfPresent(Date.self, forKey: .registeredAt) ?? Date()
        personalAccent = try container.decodeIfPresent(AccentChoice.self, forKey: .personalAccent)
        linkedChannel = try container.decodeIfPresent(String.self, forKey: .linkedChannel)
        bannerFileName = try container.decodeIfPresent(String.self, forKey: .bannerFileName)
        selectedFrameId = try container.decodeIfPresent(String.self, forKey: .selectedFrameId)
    }
}
