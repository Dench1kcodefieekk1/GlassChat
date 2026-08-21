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
