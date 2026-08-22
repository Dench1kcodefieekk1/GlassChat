import SwiftUI

/// Full-screen confetti particle effect rendered with Canvas + TimelineView.
/// Purely decorative — ignores hit testing so the chat stays interactive.
struct ConfettiView: View {
    private static let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .purple, .pink]
    private let pieceCount = 140

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                for index in 0..<pieceCount {
                    let seed = Double(index)
                    let hash = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)

                    let speed = 240 + hash * 260
                    let yOffset = (time * speed + seed * 173).truncatingRemainder(dividingBy: size.height + 80) - 40
                    let drift = sin(time * (1.2 + hash) + seed) * 34
                    let xBase = size.width * abs(sin(seed * 7.331) * 21401.17).truncatingRemainder(dividingBy: 1)
                    let x = xBase + drift

                    let width = 6 + hash * 5
                    let height = 9 + hash * 6
                    let rotation = Angle.degrees(time * 360 * (0.6 + hash) + seed * 41)
                    let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                    let path = Path(roundedRect: rect, cornerRadius: 1.5)

                    var copy = ctx
                    copy.translateBy(x: x, y: yOffset)
                    copy.rotate(by: rotation)
                    copy.opacity = 0.75 + 0.25 * sin(time * 3 + seed)
                    copy.fill(path, with: .color(Self.colors[index % Self.colors.count]))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityLabel("Celebration")
    }
}
