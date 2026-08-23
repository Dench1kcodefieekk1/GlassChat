import SwiftUI

/// Wraps any avatar with the equipped decoration frame. Static frames render
/// gradient strokes + glow shadows; animated frames drive all motion from a
/// single `TimelineView(.animation)` per frame — no repeat-forever animation
/// loops, so scrolling stays cheap.
struct AvatarFrameOverlayView<Content: View>: View {
    let frame: AvatarFrame?
    var avatarSize: CGFloat = 50
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lineWidth: CGFloat { max(2.5, avatarSize * 0.04) }

    var body: some View {
        ZStack {
            content
            if let frame {
                ring(for: frame)
                    // Circles are infinitely flexible shapes — without a hard
                    // bound the ring accepts the full proposed (screen) width.
                    .frame(width: avatarSize + 12, height: avatarSize + 12)
            }
        }
        // Strictly bind the decoration container to the avatar bounds; never
        // expand to the surrounding layout.
        .frame(width: avatarSize + 12, height: avatarSize + 12)
    }

    @ViewBuilder
    private func ring(for frame: AvatarFrame) -> some View {
        if PremiumCosmeticsManager.premiumFrameIDs.contains(frame.id) {
            if frame.id == "angelicWings" {
                // Wings render behind the avatar inside AnimatedAvatarView.
                EmptyView()
            } else if !reduceMotion {
                TimelineView(.animation) { context in
                    PremiumFrameEffectLayer(
                        frame: frame,
                        size: avatarSize + 12,
                        time: context.date.timeIntervalSinceReferenceDate
                    )
                }
            } else {
                StaticFrameRing(frame: frame, lineWidth: lineWidth)
            }
        } else if frame.isAnimated && !reduceMotion {
            TimelineView(.animation) { context in
                AnimatedFrameRing(
                    frame: frame,
                    lineWidth: lineWidth,
                    time: context.date.timeIntervalSinceReferenceDate
                )
            }
        } else {
            StaticFrameRing(frame: frame, lineWidth: lineWidth)
        }
    }
}

// MARK: - Static frames

struct StaticFrameRing: View {
    let frame: AvatarFrame
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: frame.glowColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: lineWidth
            )
            .shadow(color: frame.glowColors.first?.opacity(0.6) ?? .clear,
                    radius: lineWidth * 1.5)
    }
}

// MARK: - Animated frames

struct AnimatedFrameRing: View {
    let frame: AvatarFrame
    let lineWidth: CGFloat
    let time: TimeInterval

    var body: some View {
        switch frame.id {
        case "cyberRainbow": rainbow
        case "fireRing": spinningFire
        case "electricStorm": storm
        case "matrixStream": matrix
        case "galaxyOrbit": galaxy
        case "neonGlitch": glitch
        case "iceCrystals": ice
        case "dragonFlame": dragon
        case "crownAura": crown
        case "spectralVoid": voidRing
        default: StaticFrameRing(frame: frame, lineWidth: lineWidth)
        }
    }

    // Pulsing Cyber Rainbow — hue-cycling angular gradient + gentle pulse.
    private var rainbow: some View {
        Circle()
            .trim(from: 0.02, to: 0.98)
            .stroke(
                AngularGradient(
                    colors: frame.glowColors.map { shiftHue($0, by: time * 40) },
                    center: .center
                ),
                lineWidth: lineWidth
            )
            .rotationEffect(.degrees(time * 60))
            .scaleEffect(1 + 0.025 * sin(time * 2.4))
    }

    // Spinning Fire Ring — rotating fire angular gradient.
    private var spinningFire: some View {
        Circle()
            .trim(from: 0.03, to: 0.97)
            .stroke(
                AngularGradient(colors: frame.glowColors, center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(time * 130))
            .shadow(color: frame.glowColors[0].opacity(0.7), radius: lineWidth)
    }

    // Electric Storm — fast dashed bolts with flicker.
    private var storm: some View {
        Circle()
            .stroke(
                frame.glowColors[0],
                style: StrokeStyle(lineWidth: lineWidth, dash: [10, 6, 3, 6])
            )
            .rotationEffect(.degrees(time * 220))
            .opacity(0.65 + 0.35 * abs(sin(time * 7)))
            .shadow(color: frame.glowColors[0].opacity(0.8), radius: lineWidth * 1.4)
    }

    // Matrix Code Stream — marching green code dashes.
    private var matrix: some View {
        Circle()
            .stroke(
                LinearGradient(colors: frame.glowColors, startPoint: .top, endPoint: .bottom),
                style: StrokeStyle(lineWidth: lineWidth * 0.8, dash: [4, 5])
            )
            .rotationEffect(.degrees(-time * 90))
            .shadow(color: frame.glowColors[0].opacity(0.7), radius: lineWidth)
    }

    // Cosmic Galaxy Orbit — gradient ring with two orbiting stars.
    private var galaxy: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: frame.glowColors, startPoint: .leading, endPoint: .trailing),
                    lineWidth: lineWidth * 0.75
                )
            orbitDot(color: frame.glowColors[0], phase: time * 1.8, radius: lineWidth * 1.1)
            orbitDot(color: frame.glowColors[1], phase: time * 1.8 + .pi, radius: lineWidth * 1.1)
        }
    }

    // Neon Glitch Wave — RGB split jitter + flicker.
    private var glitch: some View {
        let jitter: CGFloat = sin(time * 31) * sin(time * 7.3) * 1.4
        return ZStack {
            Circle()
                .stroke(frame.glowColors[0], lineWidth: lineWidth)
                .offset(x: jitter, y: -jitter * 0.4)
                .opacity(0.8)
            Circle()
                .stroke(frame.glowColors[1], lineWidth: lineWidth)
                .offset(x: -jitter, y: jitter * 0.4)
                .opacity(0.8)
        }
    }

    // Frozen Ice Crystals — crystalline dashes with shimmer.
    private var ice: some View {
        Circle()
            .stroke(
                LinearGradient(colors: frame.glowColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                style: StrokeStyle(lineWidth: lineWidth, dash: [7, 7], dashPhase: CGFloat(time.truncatingRemainder(dividingBy: 14)))
            )
            .shadow(color: frame.glowColors[0].opacity(0.7), radius: lineWidth)
    }

    // Dragon Flame Aura — flickering thick stroke + breathing shadow.
    private var dragon: some View {
        Circle()
            .stroke(
                LinearGradient(colors: frame.glowColors, startPoint: .bottom, endPoint: .top),
                lineWidth: lineWidth * (0.8 + 0.35 * abs(sin(time * 5.5)))
            )
            .shadow(color: frame.glowColors[1].opacity(0.55 + 0.35 * abs(sin(time * 3.2))),
                    radius: lineWidth * (1 + abs(sin(time * 2.1))))
    }

    // Radiant Crown Aura — gold ring with orbiting crown sparkles.
    private var crown: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: frame.glowColors, startPoint: .top, endPoint: .bottom),
                    lineWidth: lineWidth
                )
                .shadow(color: frame.glowColors[0].opacity(0.6), radius: lineWidth)
            Image(systemName: "sparkle")
                .font(.system(size: lineWidth * 1.7, weight: .bold))
                .foregroundStyle(frame.glowColors[0])
                .modifier(OrbitEffect(angle: time * 90, radius: lineWidth * 2))
            Image(systemName: "sparkle")
                .font(.system(size: lineWidth * 1.2, weight: .bold))
                .foregroundStyle(frame.glowColors[1])
                .modifier(OrbitEffect(angle: time * 90 + 180, radius: lineWidth * 2))
        }
    }

    // Spectral Void — counter-rotating dark conic with violet rim.
    private var voidRing: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(colors: frame.glowColors + [frame.glowColors[0]], center: .center),
                    lineWidth: lineWidth
                )
                .rotationEffect(.degrees(time * 45))
            Circle()
                .stroke(frame.glowColors[0].opacity(0.5), lineWidth: lineWidth * 0.35)
                .rotationEffect(.degrees(-time * 30))
        }
        .shadow(color: frame.glowColors[0].opacity(0.55), radius: lineWidth * 1.6)
    }

    // MARK: - Helpers

    private func orbitDot(color: Color, phase: Double, radius: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: lineWidth * 1.1, height: lineWidth * 1.1)
            .modifier(OrbitEffect(angle: phase * 180 / .pi, radius: radius + lineWidth * 0.9))
    }

    /// Approximate hue rotation for a `Color` by re-deriving it from the
    /// rainbow gradient stop table (cheap, no CoreImage).
    private func shiftHue(_ color: Color, by degrees: Double) -> Color {
        // The rainbow palette entries are pure spectrum colors; rotating the
        // angular gradient rotation already animates the sweep, so shifting
        // per-stop keeps the cycling subtle.
        let index = Int((degrees / 60).rounded(.down)) % 6
        let palette: [Color] = [.red, .yellow, .green, .cyan, .blue, .pink]
        return palette[((index % 6) + 6) % 6].opacity(1)
    }
}

/// Places the modified view on a circular orbit around center.
struct OrbitEffect: ViewModifier {
    let angle: Double
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(
                x: radius * cos(angle * .pi / 180),
                y: radius * sin(angle * .pi / 180)
            )
    }
}
