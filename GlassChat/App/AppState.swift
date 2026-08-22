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

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .chats
    /// Chat the UI should navigate to (e.g. after the compose sheet dismisses
    /// or an in-app notification is tapped). Consumed by the chats tab.
    var pendingOpenChatID: String? = nil
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
    }
}
