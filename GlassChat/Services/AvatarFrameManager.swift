import SwiftUI

// MARK: - Model

/// A Discord-style avatar decoration frame (static stroke or animated ring).
struct AvatarFrame: Identifiable, Equatable {
    let id: String
    let name: String
    let isAnimated: Bool
    let requiredLevel: Int
    let glowColors: [Color]
}

// MARK: - Catalog & state management

@MainActor
enum AvatarFrameManager {
    /// 20 distinct frames: ten static (levels 5–40) and ten animated
    /// (levels 50–250).
    static let catalog: [AvatarFrame] = [
        // Static
        AvatarFrame(id: "neonRing", name: "Неоновое кольцо", isAnimated: false, requiredLevel: 5,
                    glowColors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.39, green: 0.83, blue: 1.0)]),
        AvatarFrame(id: "cyberGold", name: "Cyber Gold Border", isAnimated: false, requiredLevel: 10,
                    glowColors: [Color(red: 0.96, green: 0.56, blue: 0.04), Color(red: 1.0, green: 0.94, blue: 0.54)]),
        AvatarFrame(id: "frostedGlass", name: "Frosted Glass Ring", isAnimated: false, requiredLevel: 15,
                    glowColors: [Color(white: 0.92, opacity: 0.9), Color(white: 0.7, opacity: 0.7)]),
        AvatarFrame(id: "minimalPurple", name: "Minimal Purple", isAnimated: false, requiredLevel: 20,
                    glowColors: [Color(red: 0.66, green: 0.33, blue: 0.97), Color(red: 0.49, green: 0.23, blue: 0.93)]),
        AvatarFrame(id: "crimsonEdge", name: "Crimson Edge", isAnimated: false, requiredLevel: 25,
                    glowColors: [Color(red: 0.86, green: 0.15, blue: 0.15), Color(red: 0.5, green: 0.11, blue: 0.11)]),
        AvatarFrame(id: "emeraldShine", name: "Emerald Shine", isAnimated: false, requiredLevel: 30,
                    glowColors: [Color(red: 0.06, green: 0.73, blue: 0.5), Color(red: 0.43, green: 0.91, blue: 0.72)]),
        AvatarFrame(id: "oceanicBlue", name: "Oceanic Blue", isAnimated: false, requiredLevel: 35,
                    glowColors: [Color(red: 0.05, green: 0.65, blue: 0.91), Color(red: 0.12, green: 0.23, blue: 0.54)]),
        AvatarFrame(id: "pastelGlow", name: "Pastel Glow", isAnimated: false, requiredLevel: 37,
                    glowColors: [Color(red: 0.98, green: 0.66, blue: 0.83), Color(red: 0.65, green: 0.95, blue: 0.99)]),
        AvatarFrame(id: "darkObsidian", name: "Dark Obsidian", isAnimated: false, requiredLevel: 40,
                    glowColors: [Color(white: 0.28), Color(white: 0.09)]),
        AvatarFrame(id: "sunsetRing", name: "Sunset Ring", isAnimated: false, requiredLevel: 40,
                    glowColors: [Color(red: 0.98, green: 0.45, blue: 0.09), Color(red: 0.93, green: 0.28, blue: 0.6)]),
        // Animated
        AvatarFrame(id: "cyberRainbow", name: "Pulsing Cyber Rainbow", isAnimated: true, requiredLevel: 50,
                    glowColors: [.red, .yellow, .green, .cyan, .blue, .pink]),
        AvatarFrame(id: "fireRing", name: "Spinning Fire Ring", isAnimated: true, requiredLevel: 60,
                    glowColors: [Color(red: 0.94, green: 0.27, blue: 0.27), Color(red: 0.98, green: 0.45, blue: 0.09), Color(red: 1.0, green: 0.84, blue: 0.0)]),
        AvatarFrame(id: "electricStorm", name: "Electric Storm", isAnimated: true, requiredLevel: 75,
                    glowColors: [Color(red: 0.55, green: 0.75, blue: 1.0), Color(white: 0.95)]),
        AvatarFrame(id: "matrixStream", name: "Matrix Code Stream", isAnimated: true, requiredLevel: 90,
                    glowColors: [Color(red: 0.13, green: 0.9, blue: 0.3), Color(red: 0.02, green: 0.55, blue: 0.12)]),
        AvatarFrame(id: "galaxyOrbit", name: "Cosmic Galaxy Orbit", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 0.36, green: 0.2, blue: 0.85), Color(red: 0.1, green: 0.75, blue: 0.85)]),
        AvatarFrame(id: "neonGlitch", name: "Neon Glitch Wave", isAnimated: true, requiredLevel: 120,
                    glowColors: [Color(red: 1.0, green: 0.08, blue: 0.58), Color(red: 0.0, green: 0.95, blue: 0.95)]),
        AvatarFrame(id: "iceCrystals", name: "Frozen Ice Crystals", isAnimated: true, requiredLevel: 140,
                    glowColors: [Color(red: 0.75, green: 0.92, blue: 1.0), Color(white: 0.98)]),
        AvatarFrame(id: "dragonFlame", name: "Dragon Flame Aura", isAnimated: true, requiredLevel: 170,
                    glowColors: [Color(red: 0.85, green: 0.2, blue: 0.05), Color(red: 1.0, green: 0.6, blue: 0.0)]),
        AvatarFrame(id: "crownAura", name: "Radiant Crown Aura", isAnimated: true, requiredLevel: 200,
                    glowColors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.98, blue: 0.8)]),
        AvatarFrame(id: "spectralVoid", name: "Spectral Void", isAnimated: true, requiredLevel: 250,
                    glowColors: [Color(red: 0.45, green: 0.1, blue: 0.75), Color(white: 0.05)])
    ]

    static func frame(byID id: String?) -> AvatarFrame? {
        guard let id else { return nil }
        return catalog.first { $0.id == id }
    }

    static func isUnlocked(_ frame: AvatarFrame, level: Int) -> Bool {
        level >= frame.requiredLevel
    }

    /// The frame actually rendered for a user: their selection, unless the
    /// account level is still below the frame's requirement.
    static func activeFrame(selectedID: String?, level: Int) -> AvatarFrame? {
        guard let frame = frame(byID: selectedID), isUnlocked(frame, level: level) else { return nil }
        return frame
    }

    /// Equips a frame onto the active session user (`currentUser.selectedFrameId`).
    static func equip(_ frame: AvatarFrame, in store: DataStore) {
        var user = store.currentUser
        user.selectedFrameId = frame.id
        store.users[user.id] = user
        store.save()
    }

    static func unequip(in store: DataStore) {
        var user = store.currentUser
        user.selectedFrameId = nil
        store.users[user.id] = user
        store.save()
    }
}
