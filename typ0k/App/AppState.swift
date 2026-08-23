import SwiftUI
import Observation

enum AppTab: String, Hashable {
    case chats
    case contacts
    case settings
}

enum AppRoute: Hashable {
    case chat(String)
    case profile(String)
}

/// Settings pane a `.settings` detail destination points at (reserved for
/// deep-linking into a specific settings section).
enum IPadSettingsSection: String, Hashable {
    case account
    case general
    case cosmetics
}

/// Detail-column destinations for the regular-width (iPad) split layout.
enum IPadDetailDestination: Hashable {
    case chat(chatId: String)
    case profile(userId: String)
    case settings(section: IPadSettingsSection?)
    case appearance(cosmeticsSheet: Bool)
    case emptyState
}

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .chats
    /// Chat the UI should navigate to (e.g. after the compose sheet dismisses
    /// or an in-app notification is tapped). Consumed by the chats tab.
    var pendingOpenChatID: String? = nil
    /// Detail panel currently routed in the iPad split layout.
    var iPadDestination: IPadDetailDestination = .emptyState
    /// Firebase sign-in failure from the background post-OTP sync, surfaced
    /// as an alert once the user is already inside the app.
    var backgroundAuthError: String? = nil
}

@MainActor
struct AppDependencies {
    let store: DataStore
    let appState = AppState()

    init() {
        let store = DataStore.load()
        self.store = store
        NotificationService.shared.configure()
        PresenceSimulator.start(store: store)
        // +500 XP on the first launch of the day.
        UserLevelManager.shared.registerDailyLoginBonus()
    }
}
