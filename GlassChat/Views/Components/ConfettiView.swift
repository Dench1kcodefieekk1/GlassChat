import SwiftUI

/// Telegram-gift-style confetti: particles explode outward and upward from a
/// screen-space origin (the gift pill's position), then fall under gravity
/// and fade. Rendered as a full-screen overlay so nothing clips the burst.
struct ConfettiBurstView: View {
    /// Burst origin in global (screen) coordinates.
    let origin: CGPoint

    @State private var startedAt: Date?

    private static let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .purple, .pink]
    private let pieceCount = 130
    private let gravity: CGFloat = 1500

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, _ in
                guard let startedAt else { return }
                let t = context.date.timeIntervalSince(startedAt)

                for index in 0..<pieceCount {
                    let seed = Double(index)
                    let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let hash2 = abs(sin(seed * 78.233) * 12543.19).truncatingRemainder(dividingBy: 1)

                    let lifetime = 2.2 + hash * 0.9
                    guard t < lifetime else { continue }
                    let fade = t > lifetime * 0.6 ? 1 - (t - lifetime * 0.6) / (lifetime * 0.4) : 1

                    // Fan of launch directions biased upward and outward.
                    let angle = Angle.degrees(-170 + hash * 140)
                    let speed = 380 + hash2 * 520
                    let vx = sin(angle.radians) * speed
                    let vy = -cos(angle.radians) * speed

                    let x = origin.x + vx * t
                    let y = origin.y + vy * t + 0.5 * gravity * t * t

                    let width = 5 + hash * 5
                    let height = 8 + hash2 * 6
                    let rotation = Angle.degrees(t * (220 + hash * 420) * (hash2 > 0.5 ? 1 : -1))
                    let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                    let path = Path(roundedRect: rect, cornerRadius: 1.5)

                    var copy = ctx
                    copy.translateBy(x: x, y: y)
                    copy.rotate(by: rotation)
                    copy.opacity = max(0, fade)
                    copy.fill(path, with: .color(Self.colors[index % Self.colors.count]))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityLabel("Celebration")
        .onAppear { startedAt = Date() }
    }
}

/// Centered Telegram-gift-style capsule rendered as a chat stream row.
/// Reports its global frame so the confetti can burst from this exact point.
struct VerifiedGiftPill: View {
    let text: String
    var onFrame: ((CGRect) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.footnote)
            Text(text)
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.green, Color(red: 0.12, green: 0.62, blue: 0.38)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
        .shadow(color: .green.opacity(0.45), radius: 10, y: 3)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { onFrame?(geo.frame(in: .global)) }
                    .onChange(of: geo.frame(in: .global)) { _, rect in
                        onFrame?(rect)
                    }
            }
        )
        .accessibilityLabel(text)
    }
}
