import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var storageBytes: Int64 = MediaService.totalBytes()
    var showClearConfirmation = false
    var showLicenses = false

    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    func refreshStorage() {
        storageBytes = MediaService.totalBytes()
    }

    func clearCache() {
        MediaService.deleteAll()
        ImageCache.shared.clear()
        refreshStorage()
    }

    var licensesText: String {
        """
        GlassChat is built exclusively with Apple platforms frameworks:

        • SwiftUI
        • Foundation
        • Observation
        • AVFoundation
        • PhotosUI
        • UserNotifications
        • UIKit

        No third-party libraries are used at runtime.

        The demo data, names, and conversations in this prototype are fictional \
        and created for demonstration purposes only. GlassChat is not affiliated \
        with Telegram or any other messaging service.
        """
    }
}
