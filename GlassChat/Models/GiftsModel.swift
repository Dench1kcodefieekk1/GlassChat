import Foundation
import Observation

// MARK: - Rarity

enum GiftRarity: String, Hashable {
    case standard
    case nft

    var tag: String { self == .nft ? "NFT" : "GIFT" }
}

// MARK: - Gift catalog (proprietary art, fiat pricing only)

enum GiftKind: String, CaseIterable, Identifiable {
    // Standard gifts ($0.99 – $4.99 / ~40 ₴ – 200 ₴)
    case diamondRing
    case cyberCat
    case goldStar
    // Rare NFT collectibles ($150 – $2,500+ / ~6,000 ₴ – 100,000 ₴)
    case rainbowNyanCat
    case viceCream

    var id: String { rawValue }

    var rarity: GiftRarity {
        self == .rainbowNyanCat || self == .viceCream ? .nft : .standard
    }

    var title: String {
        switch self {
        case .diamondRing: return "Diamond Ring"
        case .cyberCat: return "Cyber Cat"
        case .goldStar: return "Gold Star"
        case .rainbowNyanCat: return "Rainbow Nyan Cat"
        case .viceCream: return "Vice Cream"
        }
    }

    var serialNumber: String? {
        switch self {
        case .rainbowNyanCat: return "#00404"
        case .viceCream: return "#172681"
        default: return nil
        }
    }

    /// Initial fiat price. Standard gifts also carry the hryvnia equivalent.
    var priceLabel: String {
        switch self {
        case .diamondRing: return "$4.99 · ~200 ₴"
        case .cyberCat: return "$1.99 · ~80 ₴"
        case .goldStar: return "$0.99 · ~40 ₴"
        case .rainbowNyanCat: return "$250.00"
        case .viceCream: return "$150.00"
        }
    }

    /// Estimated market value (NFT collectibles only).
    var marketValueLabel: String? {
        switch self {
        case .rainbowNyanCat: return "~$1,850.00"
        case .viceCream: return "~$1,450.00 · ~58,000 ₴"
        default: return nil
        }
    }

    // MARK: NFT attributes

    var modelName: String? {
        switch self {
        case .rainbowNyanCat: return "Cherry On Top"
        case .viceCream: return "Vice Dream"
        default: return nil
        }
    }

    var modelRarity: String { "3%" }

    var patternName: String? {
        switch self {
        case .rainbowNyanCat: return "Prismatic Wave"
        case .viceCream: return "Neon Drip"
        default: return nil
        }
    }

    var patternRarity: String { "0.4%" }

    var backgroundName: String? {
        switch self {
        case .rainbowNyanCat: return "Pop Tart Sky"
        case .viceCream: return "Sunset Fade"
        default: return nil
        }
    }

    var backgroundRarity: String { "1.5%" }

    var supplyLabel: String? {
        switch self {
        case .rainbowNyanCat: return "434,466 / 490,553"
        case .viceCream: return "172,681 / 250,000"
        default: return nil
        }
    }
}

// MARK: - Owned gift

struct GiftItem: Identifiable, Hashable {
    let id: String
    let kind: GiftKind
    let senderName: String
    let receivedAt: Date
    var isHiddenFromProfile: Bool = false
}

// MARK: - View model

@MainActor
@Observable
final class GiftsViewModel {
    private(set) var gifts: [GiftItem]
    private(set) var wornNFTID: String?

    private static let hiddenKey = "profile.hiddenGiftIDs"
    private static let wornKey = "profile.wornNFTID"

    init() {
        let hidden = Set(UserDefaults.standard.stringArray(forKey: Self.hiddenKey) ?? [])
        let now = Date()
        let catalog: [GiftItem] = [
            GiftItem(id: "gift-ring", kind: .diamondRing, senderName: "Sarah Chen",
                     receivedAt: now.addingTimeInterval(-86400 * 2 - 3600)),
            GiftItem(id: "gift-cat", kind: .cyberCat, senderName: "Mom",
                     receivedAt: now.addingTimeInterval(-86400 * 5)),
            GiftItem(id: "gift-star", kind: .goldStar, senderName: "John Carter",
                     receivedAt: now.addingTimeInterval(-3600 * 3)),
            GiftItem(id: "gift-nyan", kind: .rainbowNyanCat, senderName: "Maya Patel",
                     receivedAt: now.addingTimeInterval(-86400 * 12)),
            GiftItem(id: "gift-vice", kind: .viceCream, senderName: "Leo Novak",
                     receivedAt: now.addingTimeInterval(-86400 * 30))
        ]
        gifts = catalog.map { gift in
            var copy = gift
            copy.isHiddenFromProfile = hidden.contains(gift.id)
            return copy
        }
        wornNFTID = UserDefaults.standard.string(forKey: Self.wornKey)
    }

    func toggleHidden(_ gift: GiftItem) {
        guard let index = gifts.firstIndex(where: { $0.id == gift.id }) else { return }
        gifts[index].isHiddenFromProfile.toggle()
        UserDefaults.standard.set(
            gifts.filter(\.isHiddenFromProfile).map(\.id),
            forKey: Self.hiddenKey
        )
    }

    func toggleWorn(_ gift: GiftItem) {
        wornNFTID = (wornNFTID == gift.id) ? nil : gift.id
        UserDefaults.standard.set(wornNFTID, forKey: Self.wornKey)
    }

    func isWorn(_ gift: GiftItem) -> Bool {
        wornNFTID == gift.id
    }
}

// MARK: - Formatting

extension Date {
    /// "20.08.26 в 14:36" — gift sheet timestamp.
    var giftDateTimeLabel: String {
        let locale = Locale(identifier: "ru-RU")
        return formatted(.dateTime.day().month().year(.twoDigits).locale(locale))
            + " в "
            + formatted(.dateTime.hour().minute().locale(locale))
    }
}
