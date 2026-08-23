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
        "angelicWings", "glitchMatrix", "glowingCrown"
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
        AvatarFrame(id: "angelicWings", name: "ANGELIC WINGS", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(white: 1.0), Color(red: 0.85, green: 0.92, blue: 1.0)]),
        AvatarFrame(id: "glitchMatrix", name: "GLITCH MATRIX", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 0.13, green: 0.9, blue: 0.3), Color(red: 1.0, green: 0.08, blue: 0.58)]),
        AvatarFrame(id: "glowingCrown", name: "GLOWING CROWN", isAnimated: true, requiredLevel: 100,
                    glowColors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.97, blue: 0.75)])
    ]
}
