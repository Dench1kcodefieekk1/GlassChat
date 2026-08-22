import SwiftUI
import Lottie

/// Renders a bundled Lottie JSON as a continuously looping animation.
/// Clips at the UIKit level so animation layers can never escape the
/// (square) SwiftUI frame the caller provides.
struct GiftAnimationView: UIViewRepresentable {
    let filename: String

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: filename, bundle: .main)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.loopMode = .loop
        view.animationSpeed = 1
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.clipsToBounds = true
    }
}
