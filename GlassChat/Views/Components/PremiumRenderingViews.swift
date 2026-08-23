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

    var body: some View {
        ZStack {
            // Behind-avatar layers (wings).
            if frame?.id == "angelicWings", !reduceMotion {
                TimelineView(.animation) { context in
                    AngelWingsLayer(time: context.date.timeIntervalSinceReferenceDate)
                }
            }

            AvatarView(
                title: name,
                seed: seed,
                size: size,
                isOnline: isOnline,
                fileName: avatarFileName
            )
        }
        .frame(width: size + 12, height: size + 12)
        .overlay {
            if frame?.id == "angelicWings" {
                // Wings carry their own glow — skip the plain ring.
                EmptyView()
            } else {
                AvatarFrameOverlayView(frame: frame, avatarSize: size) {
                    Color.clear.frame(width: size, height: size)
                }
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
        case "glowingCrown":
            GlowingCrownLayer(frame: frame, size: size, time: time)
        default:
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
            let inner = outer * 0.78

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

            // Crisp inner rim.
            context.opacity = 1
            let rim = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
            context.stroke(Path(ellipseIn: rim), with: .color(frame.glowColors[1].opacity(0.8)), lineWidth: 1.5)
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
            let inner = outer * 0.82

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
            ), style: StrokeStyle(lineWidth: 2.5 + wobble * 0.4, lineCap: .round))
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
                .offset(y: -size / 2 - size * 0.1 + 2.5 * sin(time * 1.6))

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

/// ANGELIC WINGS — feathered light wings gently flapping behind the avatar.
struct AngelWingsLayer: View {
    let time: TimeInterval

    var body: some View {
        let flap = sin(time * 1.7)
        ZStack {
            WingShape(side: .left)
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.75), Color(red: 0.85, green: 0.92, blue: 1.0).opacity(0.1)],
                                   startPoint: .trailing, endPoint: .leading)
                )
                .blur(radius: 1.5)
                .rotation3DEffect(.degrees(-12 - flap * 9), axis: (x: 0, y: 1, z: 0.15))
                .offset(x: -30, y: -4)
            WingShape(side: .right)
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.75), Color(red: 0.85, green: 0.92, blue: 1.0).opacity(0.1)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .blur(radius: 1.5)
                .rotation3DEffect(.degrees(12 + flap * 9), axis: (x: 0, y: 1, z: 0.15))
                .offset(x: 30, y: -4)
        }
        .frame(width: 130, height: 80)
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

    // MARK: STATIC GLITCH — periodic RGB-split bursts.

    @ViewBuilder
    private func glitchBody(time: TimeInterval) -> some View {
        let cycle = time.truncatingRemainder(dividingBy: 2.4)
        let glitching = cycle < 0.16
        let jitter = glitching ? sin(time * 90) * 1.6 : 0.0
        ZStack {
            if glitching {
                Text(name)
                    .font(font)
                    .foregroundStyle(.red)
                    .offset(x: -jitter, y: jitter * 0.4)
                    .opacity(0.85)
                Text(name)
                    .font(font)
                    .foregroundStyle(.cyan)
                    .offset(x: jitter, y: -jitter * 0.4)
                    .opacity(0.85)
            }
            Text(name)
                .font(font)
                .foregroundStyle(glitching ? .white : .primary)
        }
    }

    // MARK: Gradients

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
