import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(DataStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        @Bindable var state = appState
        Group {
            if horizontalSizeClass == .regular {
                IPadSplitNavigationContainer()
            } else {
                compactTabs(state)
            }
        }
        .overlay {
            InAppNotificationView { banner in
                InAppNotificationCenter.shared.dismiss()
                appState.selectedTab = .chats
                appState.pendingOpenChatID = banner.chatID
            }
        }
        .overlay {
            if let level = LevelUpAudioNotifier.shared.celebrationLevel {
                LevelUpCelebrationOverlay(level: level)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85),
                   value: LevelUpAudioNotifier.shared.celebrationLevel)
    }

    private func compactTabs(_ appState: Bindable<AppState>) -> some View {
        TabView(selection: appState.selectedTab) {
            Tab("Chats", systemImage: "bubble.left.and.bubble.right.fill", value: .chats) {
                ChatsTabView()
                    .badge(store.totalUnread)
            }
            Tab("Contacts", systemImage: "person.2.fill", value: .contacts) {
                ContactsTabView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsTabView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

struct ChatsTabView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppState.self) private var appState
    @State private var model = ChatsViewModel()

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            ChatsListView(model: model)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .onChange(of: appState.pendingOpenChatID) { _, chatID in
            guard let chatID else { return }
            appState.pendingOpenChatID = nil
            // Wait out any sheet dismissal animation before pushing — pushing
            // mid-dismiss is silently dropped by UIKit (the compose bug).
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !model.showCompose else { return }
                model.popToChat(chatID)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .chat(let chatID):
            ChatView(chatID: chatID, store: store)
        case .profile(let userID):
            ProfileView(userID: userID, store: store) { chatID in
                model.popToChat(chatID)
            }
        }
    }
}

struct ContactsTabView: View {
    @Environment(DataStore.self) private var store
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ContactsListView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .chat(let chatID):
            ChatView(chatID: chatID, store: store)
        case .profile(let userID):
            ProfileView(userID: userID, store: store) { chatID in
                path.append(.chat(chatID))
            }
        }
    }
}

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            SettingsHomeView()
        }
    }
}
