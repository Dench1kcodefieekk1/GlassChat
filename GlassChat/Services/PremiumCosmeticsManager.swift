import SwiftUI

/// Premium (Nitro-grade) cosmetic definitions: shader-style animated avatar
/// decorations rendered by `PremiumRenderingViews`. All effects are native
/// SwiftUI Canvas/TimelineView particle systems — no external assets, no
/// third-party branding.
@MainActor
enum PremiumCosmeticsManager {
    /// Frame IDs owned by the premium rendering engine.
    static let premiumFrameIDs: Set<String> = [
        "galaxyVortex", "solarFlare", "arcaneRune",
        "glitchMatrix", "glowingCrown",
        "supernovaBurst", "neonDragonAura", "cyberHoloRing",
        "bloodMoonEclipse", "voidShadows",
        "plasmaVortex", "celestialOrb", "phantomFlame", "galacticCrown"
    ]

    static let premiumFrames: [AvatarFrame] = [
        // Level 50+ — animated shader-style
        AvatarFrame(id: "galaxyVortex", name: "GALAXY VORTEX", isAnimated: true, requiredLevel: 50,
                    glowColors: [Color(red: 0.28, green: 0.16, blue: 0.7), Color(red: 0.05, green: 0.6, blue: 0.85), Color(red: 0.95, green: 0.4, blue: 0.85)]),
        AvatarFrame(id: "solarFlare", name: "SOLAR FLARE", isAnimated: true, requiredLevel: 50,
                    glowColors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 1.0, green: 0.45, blue: 0.05), Color(red: 0.9, green: 0.15, blue: 0.05)]),
        AvatarFrame(id: "arcaneRune", name: "ARCANE RUNE", isAnimated: true, requiredLevel: 50,
                    glowColors: [Color(red: 0.6, green: 0.35, blue: 1.0), Color(red: 0.3, green: 0.1, blue: 0.7)]),
        // Level 100+ — mythic particles
        AvatarFrame(id: "glitchMatrix", name: "GLITCH MATRIX", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 0.13, green: 0.9, blue: 0.3), Color(red: 1.0, green: 0.08, blue: 0.58)]),
        AvatarFrame(id: "glowingCrown", name: "GLOWING CROWN", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.97, blue: 0.75)]),
        AvatarFrame(id: "supernovaBurst", name: "SUPERNOVA BURST", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 1.0, green: 0.95, blue: 0.8), Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.35, blue: 0.5)]),
        AvatarFrame(id: "neonDragonAura", name: "NEON DRAGON AURA", isAnimated: true, requiredLevel: 110,
                    glowColors: [Color(red: 0.1, green: 0.95, blue: 0.45), Color(red: 0.9, green: 0.15, blue: 0.15)]),
        AvatarFrame(id: "cyberHoloRing", name: "CYBERPUNK HOLO-RING", isAnimated: true, requiredLevel: 120,
                    glowColors: [Color(red: 0.0, green: 0.95, blue: 0.95), Color(red: 0.55, green: 0.35, blue: 1.0)]),
        AvatarFrame(id: "bloodMoonEclipse", name: "BLOOD MOON ECLIPSE", isAnimated: true, requiredLevel: 130,
                    glowColors: [Color(red: 0.85, green: 0.1, blue: 0.12), Color(white: 0.08)]),
        AvatarFrame(id: "voidShadows", name: "VOID SHADOWS", isAnimated: true, requiredLevel: 140,
                    glowColors: [Color(red: 0.5, green: 0.15, blue: 0.85), Color(white: 0.05)]),
        AvatarFrame(id: "plasmaVortex", name: "PLASMA VORTEX", isAnimated: true, requiredLevel: 180,
                    glowColors: [Color(red: 0.2, green: 0.9, blue: 1.0), Color(red: 0.85, green: 0.25, blue: 1.0), Color(red: 0.3, green: 0.4, blue: 1.0)]),
        AvatarFrame(id: "celestialOrb", name: "CELESTIAL ORB", isAnimated: true, requiredLevel: 200,
                    glowColors: [Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 1.0, green: 0.9, blue: 0.6)]),
        AvatarFrame(id: "phantomFlame", name: "PHANTOM FLAME", isAnimated: true, requiredLevel: 220,
                    glowColors: [Color(red: 0.2, green: 0.95, blue: 0.85), Color(red: 0.55, green: 0.3, blue: 0.95)]),
        AvatarFrame(id: "galacticCrown", name: "GALACTIC CROWN", isAnimated: true, requiredLevel: 250,
                    glowColors: [Color(red: 0.95, green: 0.8, blue: 0.25), Color(red: 0.55, green: 0.3, blue: 0.95)])
    ]
}
