import UIKit

/// SwiftUI's `.toolbar(.hidden, for: .navigationBar)` (used by `ChatView`'s
/// custom glass header) leaves `interactivePopGestureRecognizer` with a
/// delegate that blocks the gesture. Clearing the delegate restores the
/// native interactive swipe-left-to-right pop for every pushed screen.
extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
