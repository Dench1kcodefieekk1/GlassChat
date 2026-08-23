import SwiftUI

// MARK: - AnimatedAvatarView

/// Composites the user avatar, the online status indicator, and the active
/// decoration frame — including the premium particle/shader-style effects.
/// All effects are stateless, deterministic Canvas/TimelineView systems:
/// no Metal files, no animation loops, no accumulated state per frame.
struct AnimatedAvatarView: View {
    let name: String
    let seed: String
    var avatarFileName: String? = nil
    var size: CGFloat = 50
    var isOnline: Bool = false
    var frame: AvatarFrame?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Frame IDs whose effect renders as wings behind the avatar.
    private var isWingsFrame: Bool {
        frame?.id == "angelicWings" || frame?.id == "goldenElysiumWings"
    }

    var body: some View {
        ZStack(alignment: .center) {
            // LAYER 1: Background effects (wings, outer auras) behind the avatar.
            if let frame, isWingsFrame, !reduceMotion {
                TimelineView(.animation) { context in
                    AngelWingsLayer(
                        time: context.date.timeIntervalSinceReferenceDate,
                        avatarSize: size,
                        baseColor: frame.glowColors.first ?? .white,
                        tipColor: frame.glowColors.count > 1 ? frame.glowColors[1] : .white
                    )
                }
            }

            // LAYER 2: Main avatar image, hard-masked to a circle.
            avatarFace

            // LAYER 3: Outer animated frame ring — always larger than the
            // avatar (avatarSize + 18), never clipped across the face.
            if let frame, !isWingsFrame {
                AvatarFrameOverlayView(frame: frame, avatarSize: size) {
                    Color.clear.frame(width: size, height: size)
                }
                .allowsHitTesting(false)
            }
        }
        // Fixed outer bounding box for consistent grid alignment.
        .frame(width: size + 24, height: size + 24)
    }

    /// The user image strictly clipped to a circle; the online badge is
    /// re-composited above the mask so it survives the clip.
    private var avatarFace: some View {
        AvatarView(
            title: name,
            seed: seed,
            size: size,
            isOnline: false,
            fileName: avatarFileName
        )
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            if isOnline {
                Circle()
                    .fill(.green)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(
                        Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Premium frame layers

/// Routes premium frame IDs to their particle-system renderers.
struct PremiumFrameEffectLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        switch frame.id {
        case "galaxyVortex":
            GalaxyVortexLayer(frame: frame, size: size, time: time)
        case "solarFlare":
            SolarFlareLayer(frame: frame, size: size, time: time)
        case "arcaneRune":
            ArcaneRuneLayer(frame: frame, size: size, time: time)
        case "glitchMatrix":
            GlitchMatrixLayer(frame: frame, size: size, time: time)
        case "glowingCrown", "galacticCrown":
            GlowingCrownLayer(frame: frame, size: size, time: time)
        case "supernovaBurst":
            SupernovaBurstLayer(frame: frame, size: size, time: time)
        case "neonDragonAura":
            NeonDragonAuraLayer(frame: frame, size: size, time: time)
        case "cyberHoloRing":
            CyberHoloRingLayer(frame: frame, size: size, time: time)
        case "bloodMoonEclipse":
            BloodMoonEclipseLayer(frame: frame, size: size, time: time)
        case "voidShadows":
            VoidShadowsLayer(frame: frame, size: size, time: time)
        case "plasmaVortex":
            PlasmaVortexLayer(frame: frame, size: size, time: time)
        case "celestialOrb":
            CelestialOrbLayer(frame: frame, size: size, time: time)
        case "phantomFlame":
            PhantomFlameLayer(frame: frame, size: size, time: time)
        default:
            // goldenElysiumWings renders behind the avatar in AnimatedAvatarView.
            EmptyView()
        }
    }
}

/// GALAXY VORTEX — swirling star particles over a nebula annulus.
struct GalaxyVortexLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: (canvasSize.width / 2), y: (canvasSize.height / 2))
            let outer = min(canvasSize.width, canvasSize.height) / 2 - 2
            // Inner band stays outside the avatar circle (avatar radius is
            // ~0.81 * outer for the +18 ring padding).
            let inner = outer * 0.85

            // Nebula annulus (three soft radial hues, slowly orbiting).
            for (index, color) in frame.glowColors.enumerated() {
                let angle = time * 0.35 + Double(index) * (2 * .pi / 3)
                let nebulaCenter = CGPoint(
                    x: center.x + cos(angle) * inner * 0.55,
                    y: center.y + sin(angle) * inner * 0.55
                )
                let rect = CGRect(x: nebulaCenter.x - outer, y: nebulaCenter.y - outer,
                                  width: outer * 2, height: outer * 2)
                let nebula = Gradient(colors: [color.opacity(0.35), .clear])
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(nebula, center: nebulaCenter, startRadius: 1, endRadius: outer)
                )
            }

            // Orbiting star particles with swirl.
            for index in 0..<34 {
                let seed = Double(index)
                let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let hash2 = abs(sin(seed * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                let angle = time * (0.5 + hash * 0.7) + hash2 * 2 * .pi
                let radius = inner + hash * (outer - inner)
                let starSize = 0.8 + hash2 * 1.8
                let position = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                let twinkle = 0.4 + 0.6 * abs(sin(time * 2 + seed))
                let rect = CGRect(x: position.x - starSize, y: position.y - starSize,
                                  width: starSize * 2, height: starSize * 2)
                context.opacity = twinkle
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }

            // Crisp outer rim on the padding edge.
            context.opacity = 1
            let rim = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[1].opacity(0.8)), lineWidth: 4)
        }
        .frame(width: size, height: size)
    }
}

/// SOLAR FLARE — flickering plasma arcs and outward fire particles.
struct SolarFlareLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: (canvasSize.width / 2), y: (canvasSize.height / 2))
            let outer = min(canvasSize.width, canvasSize.height) / 2 - 2
            // Inner band stays outside the avatar circle; flares launch outward.
            let inner = outer * 0.85

            // Fire particles launching outward along the ring.
            for index in 0..<26 {
                let seed = Double(index)
                let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let hash2 = abs(sin(seed * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                let life = (time * (0.7 + hash * 0.5) + hash2).truncatingRemainder(dividingBy: 1)
                let angle = hash2 * 2 * .pi + time * 0.2
                let radius = inner + life * (outer - inner) * 1.15
                let flicker = (1 - life) * (0.6 + 0.4 * abs(sin(time * 9 + seed)))
                let particleSize = (1.5 + hash * 2.5) * (1 - life * 0.6)
                let position = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)

                let colorIndex = min(2, Int(life * 3))
                let rect = CGRect(x: position.x - particleSize, y: position.y - particleSize,
                                  width: particleSize * 2, height: particleSize * 2)
                context.opacity = max(0, flicker)
                context.fill(Path(ellipseIn: rect), with: .color(frame.glowColors[colorIndex]))
            }

            // Flickering plasma arc rim.
            context.opacity = 1
            let wobble = 2.5 * abs(sin(time * 6.3))
            let rim = CGRect(x: center.x - inner - wobble, y: center.y - inner - wobble,
                             width: (inner + wobble) * 2, height: (inner + wobble) * 2)
            var path = Path()
            path.addArc(center: center, radius: inner, startAngle: .degrees(time * 80),
                        endAngle: .degrees(time * 80 + 300), clockwise: false)
            context.opacity = 0.85
            context.stroke(path, with: .linearGradient(
                Gradient(colors: frame.glowColors),
                startPoint: CGPoint(x: center.x - inner, y: center.y),
                endPoint: CGPoint(x: center.x + inner, y: center.y)
            ), style: StrokeStyle(lineWidth: 4 + wobble * 0.4, lineCap: .round))
            context.opacity = 1
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[0].opacity(0.35)), lineWidth: 1.2)
        }
        .frame(width: size, height: size)
    }
}

/// ARCANE RUNE — rotating runic glyphs with a pulsing violet aura.
struct ArcaneRuneLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    private static let runes: [String] = ["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚺ", "ᚾ", "ᛁ", "ᛊ"]

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(colors: frame.glowColors + [frame.glowColors[0]], center: .center),
                    lineWidth: 2.5
                )
                .shadow(color: frame.glowColors[0].opacity(0.55 + 0.25 * abs(sin(time * 1.8))), radius: 5)

            ForEach(0..<Self.runes.count, id: \.self) { index in
                let angle = Double(index) / Double(Self.runes.count) * 360 + time * 22
                Text(Self.runes[index])
                    .font(.system(size: max(7, size * 0.075), weight: .semibold))
                    .foregroundStyle(frame.glowColors[0])
                    .modifier(OrbitEffect(angle: angle, radius: size / 2 - 3))
                    .opacity(0.55 + 0.45 * abs(sin(time * 2 + Double(index))))
            }
        }
        .frame(width: size, height: size)
    }
}

/// GLITCH MATRIX — digital rain characters in the ring band + chromatic
/// aberration copies of the rim.
struct GlitchMatrixLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    private static let glyphs: [String] = ["0", "1", "0", "1", "7", "3", "0", "1", "5", "9", "1", "0"]

    var body: some View {
        ZStack {
            // Chromatic aberration rims.
            Circle().stroke(frame.glowColors[1], lineWidth: 1.4)
                .offset(x: sin(time * 24) * 1.4)
                .opacity(0.7)
            Circle().stroke(frame.glowColors[0], lineWidth: 1.4)
                .offset(x: -sin(time * 24) * 1.4)
                .opacity(0.7)

            // Falling glyph band.
            Canvas { context, canvasSize in
                let center = CGPoint(x: (canvasSize.width / 2), y: (canvasSize.height / 2))
                let radius = min(canvasSize.width, canvasSize.height) / 2 - 4
                for index in 0..<Self.glyphs.count {
                    let hash = abs(sin(Double(index) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let fall = (time * (0.35 + hash * 0.4) + hash).truncatingRemainder(dividingBy: 1)
                    let angle = Double(index) / Double(Self.glyphs.count) * 2 * .pi + 0.12
                    let position = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    var copy = context
                    copy.opacity = (1 - fall) * (0.5 + 0.5 * abs(sin(time * 3 + Double(index))))
                    copy.draw(
                        Text(Self.glyphs[index])
                            .font(.system(size: max(5, size * 0.06), design: .monospaced))
                            .foregroundColor(.green),
                        at: position
                    )
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// GLOWING CROWN — golden crown above the avatar with rising sparkles.
struct GlowingCrownLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: frame.glowColors, startPoint: .top, endPoint: .bottom),
                    lineWidth: 2.5
                )
                .shadow(color: frame.glowColors[0].opacity(0.6), radius: 4)

            // Crown floating above the ring, gently bobbing.
            CrownShape()
                .fill(
                    LinearGradient(colors: frame.glowColors, startPoint: .bottom, endPoint: .top)
                )
                .frame(width: size * 0.34, height: size * 0.2)
                .shadow(color: frame.glowColors[0].opacity(0.75), radius: 4)
                .offset(y: -size / 2 - 4 + 2.5 * sin(time * 1.6))

            // Rising sparkle particles around the crown.
            Canvas { context, canvasSize in
                for index in 0..<8 {
                    let hash = abs(sin(Double(index) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let hash2 = abs(sin(Double(index) * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                    let life = (time * (0.5 + hash * 0.4) + hash2).truncatingRemainder(dividingBy: 1)
                    let x = (canvasSize.width / 2) + (hash - 0.5) * size * 0.5
                    let y = (canvasSize.height / 2) - size * 0.55 - life * size * 0.35
                    let sparkSize = (1 + hash2 * 1.6) * (1 - life)
                    let rect = CGRect(x: x - sparkSize, y: y - sparkSize,
                                      width: sparkSize * 2, height: sparkSize * 2)
                    context.opacity = max(0, 1 - life)
                    context.fill(Path(ellipseIn: rect), with: .color(frame.glowColors[1]))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// SUPERNOVA BURST — expanding shockwave rings plus outward white-hot sparks.
struct SupernovaBurstLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outer = min(canvasSize.width, canvasSize.height) / 2 - 2
            let inner = outer * 0.8

            for wave in 0..<3 {
                let life = (time * 0.8 + Double(wave) / 3).truncatingRemainder(dividingBy: 1)
                let radius = inner + life * (outer - inner) * 1.2
                let rect = CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2)
                context.opacity = (1 - life) * 0.65
                context.stroke(Path(ellipseIn: rect), with: .color(frame.glowColors[wave % frame.glowColors.count]), lineWidth: 1.4)
            }

            for index in 0..<20 {
                let seed = Double(index)
                let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let hash2 = abs(sin(seed * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                let life = (time * (0.9 + hash * 0.6) + hash2).truncatingRemainder(dividingBy: 1)
                let angle = hash2 * 2 * .pi
                let radius = inner + life * (outer - inner) * 1.25
                let spark = (1.2 + hash * 2) * (1 - life * 0.6)
                let position = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                let rect = CGRect(x: position.x - spark, y: position.y - spark, width: spark * 2, height: spark * 2)
                context.opacity = max(0, 1 - life)
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }

            context.opacity = 0.9
            let rim = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[0].opacity(0.8)), lineWidth: 1.6)
        }
        .frame(width: size, height: size)
    }
}

/// NEON DRAGON AURA — thick breathing neon coil with a hot flicker shadow.
struct NeonDragonAuraLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(colors: frame.glowColors + [frame.glowColors[0]], center: .center),
                    lineWidth: 2.6 + 1.6 * abs(sin(time * 4.2))
                )
                .rotationEffect(.degrees(time * 55))
                .shadow(color: frame.glowColors[0].opacity(0.6 + 0.3 * abs(sin(time * 6))), radius: 6)
            Circle()
                .stroke(frame.glowColors[1].opacity(0.5), lineWidth: 1)
                .rotationEffect(.degrees(-time * 35))
        }
        .frame(width: size, height: size)
    }
}

/// CYBERPUNK HOLO-RING — counter-rotating dashed hologram bands with scan flicker.
struct CyberHoloRingLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(frame.glowColors[0], style: StrokeStyle(lineWidth: 1.8, dash: [6, 4]))
                .rotationEffect(.degrees(time * 130))
            Circle()
                .stroke(frame.glowColors[1].opacity(0.7), style: StrokeStyle(lineWidth: 1.1, dash: [2, 3]))
                .rotationEffect(.degrees(-time * 90))
        }
        .opacity(0.7 + 0.3 * abs(sin(time * 5)))
        .shadow(color: frame.glowColors[0].opacity(0.6), radius: 4)
        .frame(width: size, height: size)
    }
}

/// BLOOD MOON ECLIPSE — crimson glow annulus with a slow eclipsing dark limb.
struct BloodMoonEclipseLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outer = min(canvasSize.width, canvasSize.height) / 2 - 2
            let inner = outer * 0.8

            let glow = Gradient(colors: [frame.glowColors[0].opacity(0.55), .clear])
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)),
                with: .radialGradient(glow, center: center, startRadius: inner * 0.9, endRadius: outer)
            )

            context.opacity = 0.95
            let rim = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[0]), lineWidth: 2)

            // Dark limb sliding around the rim like an eclipse shadow.
            var eclipse = Path()
            let phase = time * 40
            eclipse.addArc(center: center, radius: inner, startAngle: .degrees(phase),
                           endAngle: .degrees(phase + 110), clockwise: false)
            context.opacity = 0.8
            context.stroke(eclipse, with: .color(frame.glowColors[1]), lineWidth: 3.4)
        }
        .frame(width: size, height: size)
    }
}

/// VOID SHADOWS — dark smoke wisps circling the rim under a violet edge.
struct VoidShadowsLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(frame.glowColors[0].opacity(0.85), lineWidth: 1.6)
                .shadow(color: frame.glowColors[0].opacity(0.6), radius: 5)

            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(canvasSize.width, canvasSize.height) / 2 - 4
                for index in 0..<10 {
                    let seed = Double(index)
                    let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let angle = time * (0.5 + hash * 0.4) + seed * 0.63
                    let wisp = 2.5 + hash * 3
                    let position = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                    let rect = CGRect(x: position.x - wisp, y: position.y - wisp, width: wisp * 2, height: wisp * 2)
                    context.opacity = 0.35 + 0.3 * abs(sin(time * 2 + seed))
                    context.fill(Path(ellipseIn: rect), with: .color(frame.glowColors[1]))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// PLASMA VORTEX — fast-spinning charged annulus with crackling particles.
struct PlasmaVortexLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outer = min(canvasSize.width, canvasSize.height) / 2 - 2
            let inner = outer * 0.8

            for (index, color) in frame.glowColors.enumerated() {
                let angle = time * 0.9 + Double(index) * (2 * .pi / Double(frame.glowColors.count))
                let blob = CGPoint(x: center.x + cos(angle) * inner * 0.9, y: center.y + sin(angle) * inner * 0.9)
                let gradient = Gradient(colors: [color.opacity(0.4), .clear])
                let rect = CGRect(x: blob.x - outer, y: blob.y - outer, width: outer * 2, height: outer * 2)
                context.opacity = 1
                context.fill(Path(ellipseIn: rect),
                             with: .radialGradient(gradient, center: blob, startRadius: 1, endRadius: outer * 0.8))
            }

            for index in 0..<24 {
                let seed = Double(index)
                let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let angle = time * (1.6 + hash) + seed * 0.26
                let radius = inner + hash * (outer - inner)
                let dot = 0.7 + hash * 1.3
                let position = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                let rect = CGRect(x: position.x - dot, y: position.y - dot, width: dot * 2, height: dot * 2)
                context.opacity = 0.5 + 0.5 * abs(sin(time * 4 + seed))
                context.fill(Path(ellipseIn: rect), with: .color(frame.glowColors[index % frame.glowColors.count]))
            }

            context.opacity = 0.9
            let rim = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[0].opacity(0.7)), lineWidth: 1.3)
        }
        .frame(width: size, height: size)
    }
}

/// CELESTIAL ORB — serene halo with slow orbiting star sparkles.
struct CelestialOrbLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: frame.glowColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 2
                )
                .shadow(color: frame.glowColors[0].opacity(0.5 + 0.25 * abs(sin(time * 1.4))), radius: 6)

            Image(systemName: "sparkle")
                .font(.system(size: max(6, size * 0.06), weight: .bold))
                .foregroundStyle(frame.glowColors[0])
                .modifier(OrbitEffect(angle: time * 40, radius: size / 2 - 2))
            Image(systemName: "sparkle")
                .font(.system(size: max(5, size * 0.045), weight: .bold))
                .foregroundStyle(frame.glowColors[1])
                .modifier(OrbitEffect(angle: time * 40 + 120, radius: size / 2 - 2))
            Image(systemName: "sparkle")
                .font(.system(size: max(4, size * 0.04), weight: .bold))
                .foregroundStyle(frame.glowColors[0].opacity(0.8))
                .modifier(OrbitEffect(angle: time * 40 + 240, radius: size / 2 - 2))
        }
        .frame(width: size, height: size)
    }
}

/// PHANTOM FLAME — spectral teal fire drifting up around the rim.
struct PhantomFlameLayer: View {
    let frame: AvatarFrame
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(frame.glowColors[0].opacity(0.55), lineWidth: 1.4)
                .shadow(color: frame.glowColors[0].opacity(0.6), radius: 4)

            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(canvasSize.width, canvasSize.height) / 2 - 5
                for index in 0..<18 {
                    let seed = Double(index)
                    let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let hash2 = abs(sin(seed * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                    let life = (time * (0.6 + hash * 0.5) + hash2).truncatingRemainder(dividingBy: 1)
                    let angle = hash * 2 * .pi + sin(time * 1.5 + seed) * 0.15
                    let lift = life * size * 0.18
                    let position = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius - lift
                    )
                    let flame = (1.4 + hash2 * 2.2) * (1 - life * 0.6)
                    let rect = CGRect(x: position.x - flame, y: position.y - flame,
                                      width: flame * 2, height: flame * 2)
                    context.opacity = max(0, 0.8 - life)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(index % 2 == 0 ? frame.glowColors[0] : frame.glowColors[1]))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// ANGELIC WINGS — feathered light wings gently flapping behind the avatar.
/// Wings span `avatarSize * 1.5`, extending to each side of the circle.
struct AngelWingsLayer: View {
    let time: TimeInterval
    var avatarSize: CGFloat = 108
    var baseColor: Color = .white
    var tipColor: Color = Color(red: 0.85, green: 0.92, blue: 1.0)

    var body: some View {
        let flap = sin(time * 1.7)
        let spread = avatarSize * 0.3
        ZStack {
            WingShape(side: .left)
                .fill(
                    LinearGradient(colors: [baseColor.opacity(0.75), tipColor.opacity(0.1)],
                                   startPoint: .trailing, endPoint: .leading)
                )
                .blur(radius: 1.5)
                .rotation3DEffect(.degrees(-12 - flap * 9), axis: (x: 0, y: 1, z: 0.15))
                .offset(x: -spread, y: -avatarSize * 0.04)
            WingShape(side: .right)
                .fill(
                    LinearGradient(colors: [baseColor.opacity(0.75), tipColor.opacity(0.1)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .blur(radius: 1.5)
                .rotation3DEffect(.degrees(12 + flap * 9), axis: (x: 0, y: 1, z: 0.15))
                .offset(x: spread, y: -avatarSize * 0.04)
        }
        .frame(width: avatarSize * 1.5, height: avatarSize * 0.8)
        .opacity(0.9)
    }
}

/// One feathered wing built from layered arcs.
struct WingShape: Shape {
    enum Side { case left, right }

    let side: Side

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let origin = CGPoint(x: side == .left ? rect.maxX : rect.minX, y: rect.midY)
        let length = rect.width
        for feather in 0..<5 {
            let progress = Double(feather) / 5
            let featherLength = length * (1 - progress * 0.55)
            let angle = (-55 + Double(feather) * 26) * (side == .left ? 1 : -1)
            let radians = angle * .pi / 180
            let end = CGPoint(
                x: origin.x + cos(radians) * featherLength * (side == .left ? -1 : 1),
                y: origin.y + sin(radians) * featherLength * 0.85
            )
            let control = CGPoint(
                x: origin.x + (end.x - origin.x) * 0.45,
                y: origin.y + (end.y - origin.y) * 0.45 - 14
            )
            path.move(to: origin)
            path.addQuadCurve(to: end, control: control)
            path.addQuadCurve(
                to: origin,
                control: CGPoint(x: (origin.x + end.x) / 2, y: max(origin.y, end.y) + 8)
            )
            path.closeSubpath()
        }
        return path
    }
}

/// Simple five-point crown silhouette.
struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.maxY * 0.65))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.maxY * 0.65))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - AnimatedNicknameView

/// Renders the nickname with premium shader-style text effects. Legacy
/// styles delegate to `NicknameText`.
struct AnimatedNicknameView: View {
    let name: String
    let style: NicknameStyleID
    var font: Font = .title2.weight(.semibold)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch style {
        case .standard, .neonViolet, .cyberGold, .rainbow, .fireCrown:
            NicknameText(name: name, style: style, font: font)
        case .burningText:
            burning
        case .rainbowWave:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(rainbowWaveGradient(at: time))
                    .shadow(color: .orange.opacity(0.5), radius: 3)
            }
        case .staticGlitch:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                glitchBody(time: time)
            }
        case .neonPulse:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let breath = 0.5 + 0.5 * sin(time * 1.8)
                Text(name)
                    .font(font)
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(hue: 0.55 + 0.12 * sin(time * 0.7), saturation: 1, brightness: 1)
                        .opacity(0.55 + 0.45 * breath),
                        radius: 3 + 9 * breath)
                    .shadow(color: Color(hue: 0.55 + 0.12 * sin(time * 0.7), saturation: 1, brightness: 1)
                        .opacity(0.35 * breath),
                        radius: 2)
            }
        case .galaxyText:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(galaxyGradient(at: time))
                    .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.9).opacity(0.6), radius: 4)
            }
        case .deepGalaxyRGB:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.25),
                        Color(red: 0.4, green: 0.15, blue: 0.85),
                        Color(red: 0.1, green: 0.6, blue: 0.95),
                        Color(red: 0.85, green: 0.3, blue: 0.85)
                    ], time: time, speed: 0.35))
                    .shadow(color: Color(red: 0.3, green: 0.2, blue: 0.9).opacity(0.75), radius: 5)
            }
        case .liquidGold:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.55, green: 0.38, blue: 0.05),
                        Color(red: 1.0, green: 0.93, blue: 0.55),
                        Color(red: 0.85, green: 0.62, blue: 0.1),
                        Color(red: 1.0, green: 0.85, blue: 0.35)
                    ], time: time, speed: 0.45))
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.25).opacity(0.65), radius: 4)
            }
        case .infernoFlame:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.95, green: 0.2, blue: 0.05), location: 0),
                                .init(color: .orange, location: 0.5 + 0.1 * sin(time * 5)),
                                .init(color: .yellow, location: 1)
                            ],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .shadow(color: .red.opacity(0.55 + 0.3 * abs(sin(time * 6))), radius: 5)
            }
        case .electricPlasma:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let zap = 0.55 + 0.45 * abs(sin(time * 8))
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.2, green: 0.95, blue: 1.0),
                        Color(red: 0.55, green: 0.35, blue: 1.0),
                        Color(red: 0.9, green: 0.98, blue: 1.0)
                    ], time: time, speed: 0.7))
                    .shadow(color: Color(red: 0.3, green: 0.85, blue: 1.0).opacity(zap), radius: 3 + 6 * zap)
            }
        case .cherryBlossomNeon:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 1.0, green: 0.72, blue: 0.86),
                        Color(red: 1.0, green: 0.45, blue: 0.7),
                        Color(red: 0.98, green: 0.9, blue: 1.0)
                    ], time: time, speed: 0.3))
                    .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.75)
                        .opacity(0.6 + 0.3 * abs(sin(time * 2.2))), radius: 5)
            }
        case .blackHoleShimmer:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let shimmer = 0.35 + 0.65 * abs(sin(time * 1.6))
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.12, green: 0.02, blue: 0.2),
                        Color(red: 0.35, green: 0.1, blue: 0.5),
                        Color(white: 0.08)
                    ], time: time, speed: 0.25))
                    .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0).opacity(shimmer), radius: 2 + 5 * shimmer)
            }
        case .cyberGlitchMatrix:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let glitching = time.truncatingRemainder(dividingBy: 1.3) < 0.2
                let jitter = glitching ? sin(time * 140) * 1.6 : 0.0
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.05, green: 0.95, blue: 0.35),
                        Color(red: 0.0, green: 0.45, blue: 0.15),
                        Color(red: 0.5, green: 1.0, blue: 0.65)
                    ], time: time, speed: 0.5))
                    .offset(x: jitter)
                    .shadow(color: Color(red: 0.1, green: 0.9, blue: 0.3).opacity(0.7), radius: 4)
            }
        case .neonEmerald:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let breath = 0.5 + 0.5 * sin(time * 2)
                Text(name)
                    .font(font)
                    .foregroundStyle(sweepingGradient(colors: [
                        Color(red: 0.1, green: 0.95, blue: 0.55),
                        Color(red: 0.0, green: 0.65, blue: 0.4),
                        Color(red: 0.6, green: 1.0, blue: 0.8)
                    ], time: time, speed: 0.3))
                    .shadow(color: Color(red: 0.1, green: 0.95, blue: 0.55).opacity(0.5 + 0.4 * breath),
                            radius: 3 + 7 * breath)
            }
        }
    }

    // MARK: BURNING TEXT — flame gradient + rising embers above the glyphs.

    private var burning: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Text(name)
                .font(font)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .yellow, location: 0),
                            .init(color: .orange, location: 0.45),
                            .init(color: Color(red: 0.9, green: 0.15, blue: 0.05),
                                  location: 0.55 + 0.12 * sin(time * 4)),
                            .init(color: .red.opacity(0.85), location: 1)
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                )
                .shadow(color: .orange.opacity(0.7), radius: 3 + 2 * abs(sin(time * 5)))
                .overlay(alignment: .top) {
                    Canvas { canvasContext, canvasSize in
                        for index in 0..<12 {
                            let hash = abs(sin(Double(index) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                            let hash2 = abs(sin(Double(index) * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)
                            let life = (time * (0.8 + hash * 0.6) + hash2).truncatingRemainder(dividingBy: 1)
                            let x = canvasSize.width * (0.08 + 0.84 * hash) + sin(time * 3 + Double(index)) * 2
                            let y = canvasSize.height * (1 - life)
                            let emberSize = (1 + hash2 * 1.4) * (1 - life * 0.7)
                            let rect = CGRect(x: x - emberSize, y: y - emberSize,
                                              width: emberSize * 2, height: emberSize * 2)
                            canvasContext.opacity = max(0, 0.85 - life)
                            canvasContext.fill(
                                Path(ellipseIn: rect),
                                with: .color(life < 0.4 ? .yellow : .orange)
                            )
                        }
                    }
                    .frame(height: 14)
                    .allowsHitTesting(false)
                    .offset(y: -6)
                }
        }
    }

    // MARK: STATIC GLITCH — rapid RGB-split bursts with pixel jitter.

    @ViewBuilder
    private func glitchBody(time: TimeInterval) -> some View {
        // Burst windows recur fast (every 1.1s) and last ~20% of the cycle.
        let cycle = time.truncatingRemainder(dividingBy: 1.1)
        let glitching = cycle < 0.22
        // High-frequency displacement: chromatic aberration on both axes.
        let burst = glitching ? sin(time * 160) * 2.6 : 0.0
        let vertical = glitching ? cos(time * 120) * 1.1 : 0.0
        // Micro-flicker keeps the ghost copies strobing inside a burst.
        let flicker = glitching ? 0.65 + 0.35 * abs(sin(time * 240)) : 0.0
        // Horizontal pixel jitter shakes the base glyphs during bursts.
        let jitterX = glitching ? sin(time * 210) * 1.3 : 0.0
        ZStack {
            if glitching {
                Text(name)
                    .font(font)
                    .foregroundStyle(.red)
                    .offset(x: -burst, y: vertical)
                    .opacity(flicker)
                Text(name)
                    .font(font)
                    .foregroundStyle(.cyan)
                    .offset(x: burst, y: -vertical)
                    .opacity(flicker)
            }
            Text(name)
                .font(font)
                .foregroundStyle(glitching ? .white : .primary)
                .offset(x: jitterX)
                .opacity(glitching ? 0.8 + 0.2 * abs(sin(time * 300)) : 1)
        }
    }

    // MARK: Gradients

    /// Linear gradient whose axis sweeps around the text over time.
    private func sweepingGradient(colors: [Color], time: TimeInterval, speed: Double) -> LinearGradient {
        let angle = time * speed * 2 * .pi
        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(x: 0.5 + cos(angle) * 0.5, y: 0.5 + sin(angle) * 0.5),
            endPoint: UnitPoint(x: 0.5 - cos(angle) * 0.5, y: 0.5 - sin(angle) * 0.5)
        )
    }

    private func rainbowWaveGradient(at time: TimeInterval) -> LinearGradient {
        let colors = (0..<6).map { index -> Color in
            var hue = (time * 0.12 + Double(index) / 6.0).truncatingRemainder(dividingBy: 1)
            if hue < 0 { hue += 1 }
            return Color(hue: hue, saturation: 0.85, brightness: 1)
        }
        let angle = time * 0.12 * 2 * .pi
        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(x: 0.5 + cos(angle - .pi) * 0.5, y: 0.5 + sin(angle - .pi) * 0.5),
            endPoint: UnitPoint(x: 0.5 + cos(angle) * 0.5, y: 0.5 + sin(angle) * 0.5)
        )
    }

    private func galaxyGradient(at time: TimeInterval) -> LinearGradient {
        let colors: [Color] = [
            Color(red: 0.15, green: 0.08, blue: 0.35),
            Color(red: 0.45, green: 0.2, blue: 0.85),
            Color(red: 0.15, green: 0.65, blue: 0.95),
            Color(red: 0.9, green: 0.35, blue: 0.8),
            Color(red: 0.1, green: 0.06, blue: 0.3)
        ]
        let shift = time * 0.25
        return LinearGradient(
            colors: colors.map { color in color.opacity(1) },
            startPoint: UnitPoint(x: 0.5 + cos(shift) * 0.5, y: 0.5 + sin(shift) * 0.5),
            endPoint: UnitPoint(x: 0.5 - cos(shift) * 0.5, y: 0.5 - sin(shift) * 0.5)
        )
    }
}
