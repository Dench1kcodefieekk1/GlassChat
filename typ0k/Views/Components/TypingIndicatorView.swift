import SwiftUI

/// Animated three-dot typing indicator with a staggered bounce.
struct TypingDotsView: View {
    var dotColor: Color = Color(uiColor: .secondaryLabel)
    var dotSize: CGFloat = 5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        HStack(spacing: dotSize * 0.65) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: offset(for: index))
                    .animation(dotAnimation(for: index), value: animating)
            }
        }
        .onAppear { animating = true }
        .onDisappear { animating = false }
        .accessibilityHidden(true)
    }

    private func offset(for index: Int) -> CGFloat {
        guard !reduceMotion else { return 0 }
        return animating ? -dotSize * 0.45 : dotSize * 0.45
    }

    private func dotAnimation(for index: Int) -> Animation? {
        if reduceMotion {
            return .default
        }
        return .easeInOut(duration: 0.45)
            .repeatForever(autoreverses: true)
            .delay(Double(index) * 0.14)
    }
}

/// "John is typing ● ● ●" variant used in headers and chat rows.
struct TypingStatusView: View {
    let name: String
    var font: Font = .subheadline

    var body: some View {
        HStack(spacing: 6) {
            Text("\(name) is typing")
                .font(font)
                .foregroundStyle(.tint)
            TypingDotsView(dotColor: .accentColor, dotSize: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) is typing")
    }
}
