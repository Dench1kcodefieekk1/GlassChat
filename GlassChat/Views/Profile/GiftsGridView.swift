import SwiftUI

/// 3-column Telegram-style grid of owned gifts and NFT collectibles.
/// Every cell renders a proprietary procedural graphic — no external assets.
struct GiftsGridView: View {
    let gifts: [GiftItem]
    let onTap: (GiftItem) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        if gifts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("No gifts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gifts) { gift in
                    GiftCell(gift: gift)
                        .onTapGesture { onTap(gift) }
                }
            }
        }
    }
}

// MARK: - Cell

private struct GiftCell: View {
    let gift: GiftKind

    init(gift: GiftItem) {
        self.gift = gift.kind
    }

    var body: some View {
        VStack(spacing: 8) {
            GiftGraphicView(kind: gift)
                .frame(height: 64)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            Text(gift.rarity.tag)
                .font(.system(size: 10, weight: .bold))
                .monospaced()
                .foregroundStyle(gift.rarity == .nft ? AnyShapeStyle(.white) : AnyShapeStyle(.primary.opacity(0.75)))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    gift.rarity == .nft
                        ? AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color(uiColor: .tertiarySystemFill)),
                    in: Capsule()
                )
        }
        .padding(10)
        .frame(height: 118)
        .frame(maxWidth: .infinity)
        .background(cardGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .accessibilityLabel("\(gift.title) \(gift.rarity.tag)")
    }

    private var cardGradient: AnyShapeStyle {
        switch gift {
        case .diamondRing:
            return AnyShapeStyle(LinearGradient(colors: [Color.indigo.opacity(0.35), Color.cyan.opacity(0.25)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .cyberCat:
            return AnyShapeStyle(LinearGradient(colors: [Color.teal.opacity(0.32), Color.mint.opacity(0.2)],
                                                startPoint: .top, endPoint: .bottom))
        case .goldStar:
            return AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.76, blue: 0.2).opacity(0.35), Color.yellow.opacity(0.18)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .rainbowNyanCat:
            return AnyShapeStyle(LinearGradient(colors: [Color.pink.opacity(0.35), Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .viceCream:
            return AnyShapeStyle(LinearGradient(colors: [Color.orange.opacity(0.32), Color.pink.opacity(0.25)],
                                                startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - Procedural graphics

/// Clockwork shared by all gift graphics: continuous time-driven animation.
struct GiftGraphicView: View {
    let kind: GiftKind
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Group {
                switch kind {
                case .diamondRing: DiamondRingGraphic(time: t)
                case .cyberCat: CyberCatGraphic(time: t)
                case .goldStar: GoldStarGraphic(time: t)
                case .rainbowNyanCat: RainbowNyanCatGraphic(time: t)
                case .viceCream: ViceCreamGraphic(time: t)
                }
            }
        }
    }
}

// MARK: Diamond Ring — rotating gem with light flares ($4.99 / ~200 ₴)

private struct DiamondRingGraphic: View {
    let time: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Gold band
            Circle()
                .stroke(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.78, blue: 0.35), Color(red: 0.85, green: 0.6, blue: 0.2)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 5
                )
                .frame(width: 46, height: 46)

            // Gem with sweeping flare
            DiamondShape()
                .fill(
                    LinearGradient(colors: [Color.white, Color(red: 0.6, green: 0.9, blue: 1.0), Color(red: 0.3, green: 0.6, blue: 0.95)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(DiamondShape().stroke(.white.opacity(0.8), lineWidth: 1))
                .frame(width: 26, height: 26)
                .offset(y: -25)
                .rotationEffect(.degrees(reduceMotion ? 0 : sin(time * 1.4) * 8))
                .shadow(color: .cyan.opacity(0.8), radius: flare * 6)

            // Sparkle flares
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 20, y: -32)
                .opacity(0.4 + 0.6 * abs(sin(time * 2.2)))
            Image(systemName: "sparkle")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: -22, y: -22)
                .opacity(0.3 + 0.7 * abs(sin(time * 1.7 + 1)))
        }
    }

    private var flare: Double { 0.5 + 0.5 * abs(sin(time * 2.0)) }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: Cyber Cat — blinking neon cat ($1.99 / ~80 ₴)

private struct CyberCatGraphic: View {
    let time: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var blink: CGFloat {
        // Quick double-blink every ~3 seconds.
        let cycle = time.truncatingRemainder(dividingBy: 3.2)
        if cycle < 0.12 || (cycle > 0.22 && cycle < 0.32) { return 0.1 }
        return 1
    }

    var body: some View {
        ZStack {
            // Ears
            TriangleShape()
                .fill(Color.teal)
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(-12))
                .offset(x: -16, y: -18)
            TriangleShape()
                .fill(Color.teal)
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(12))
                .offset(x: 16, y: -18)

            // Head with scanlines
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.55, blue: 0.55), Color(red: 0.05, green: 0.35, blue: 0.4)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 46)
                .overlay(
                    Circle().stroke(.mint.opacity(0.7), lineWidth: 1.5)
                )

            // Eyes (blink by vertical scale)
            HStack(spacing: 12) {
                Capsule()
                    .fill(Color(red: 0.5, green: 1.0, blue: 0.8))
                    .frame(width: 7, height: 12)
                    .scaleEffect(y: blink)
                Capsule()
                    .fill(Color(red: 0.5, green: 1.0, blue: 0.8))
                    .frame(width: 7, height: 12)
                    .scaleEffect(y: blink)
            }
            .shadow(color: .mint, radius: 4)

            // Nose / mouth dot
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 4, height: 4)
                .offset(y: 10)
        }
        .scaleEffect(reduceMotion ? 1 : 1 + 0.02 * sin(time * 2.4))
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: Gold Star — pulsing star with aura ($0.99 / ~40 ₴)

private struct GoldStarGraphic: View {
    let time: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pulse: CGFloat { reduceMotion ? 1 : 1 + 0.09 * sin(time * 2.6) }

    var body: some View {
        ZStack {
            RadialGradient(colors: [Color.yellow.opacity(0.65), .clear],
                           center: .center, startRadius: 2, endRadius: 34)
                .frame(width: 68, height: 68)
                .scaleEffect(reduceMotion ? 1 : 1 + 0.14 * sin(time * 2.6 + 0.5))

            StarShape(points: 5)
                .fill(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.95, green: 0.65, blue: 0.1)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(StarShape(points: 5).stroke(.white.opacity(0.7), lineWidth: 1))
                .frame(width: 40, height: 40)
                .scaleEffect(pulse)
                .shadow(color: .yellow.opacity(0.9), radius: 8)
        }
    }
}

private struct StarShape: Shape {
    let points: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        for index in 0..<(points * 2) {
            let angle = Angle.degrees(Double(index) / Double(points * 2) * 360 - 90).radians
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: Rainbow Nyan Cat — continuous hue rotation (#00404, ~$1,850.00)

private struct RainbowNyanCatGraphic: View {
    let time: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rainbow: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple]
    }

    var body: some View {
        ZStack {
            // Rainbow trail
            HStack(spacing: 2) {
                ForEach(Array(rainbow.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 5, height: 24)
                }
            }
            .offset(x: -24)
            .hueRotation(.degrees(reduceMotion ? 0 : time * 60))

            // Pixel body
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.95, green: 0.4, blue: 0.65))
                .frame(width: 34, height: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )

            // Head
            Circle()
                .fill(Color(red: 0.98, green: 0.6, blue: 0.75))
                .frame(width: 22, height: 22)
                .offset(x: 22, y: -6)

            // Eyes + blush
            Circle().fill(.black).frame(width: 3, height: 3).offset(x: 19, y: -8)
            Circle().fill(.black).frame(width: 3, height: 3).offset(x: 26, y: -8)
            Circle().fill(.white.opacity(0.6)).frame(width: 5, height: 3).offset(x: 15, y: -3)
        }
        .hueRotation(.degrees(reduceMotion ? 0 : time * 60))
        .scaleEffect(reduceMotion ? 1 : 1 + 0.04 * sin(time * 3.0))
    }
}

// MARK: Vice Cream — steaming ice cream (#172681, ~$1,450.00)

private struct ViceCreamGraphic: View {
    let time: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Rising steam particles
            ForEach(0..<3, id: \.self) { index in
                let phase = (time * 18 + Double(index) * 14).truncatingRemainder(dividingBy: 42)
                Circle()
                    .fill(Color.white.opacity(0.55 * (1 - phase / 42)))
                    .frame(width: 4 + CGFloat(index), height: 4 + CGFloat(index))
                    .offset(x: CGFloat(index - 1) * 8 + sin(time * 2 + Double(index)) * 2,
                            y: -20 - phase)
            }

            // Scoops (vice palette: teal → pink)
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.8, blue: 0.75), Color(red: 0.1, green: 0.5, blue: 0.55)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 22, height: 22)
                .offset(y: -8)
            Circle()
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.7), Color(red: 0.85, green: 0.25, blue: 0.55)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 26, height: 26)
                .offset(y: 6)

            // Cone
            ViceCreamConeShape()
                .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.75, blue: 0.45), Color(red: 0.8, green: 0.55, blue: 0.3)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 26, height: 26)
                .offset(y: 26)
        }
        .scaleEffect(reduceMotion ? 1 : 1 + 0.03 * sin(time * 2.2))
    }
}

private struct ViceCreamConeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
