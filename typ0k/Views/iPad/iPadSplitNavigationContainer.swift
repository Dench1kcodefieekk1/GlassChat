import SwiftUI

/// Regular-width (iPad) root: a `NavigationSplitView` with a 320–380pt
/// glass sidebar (chats / contacts / settings) and a detail column driven by
/// `AppState.iPadDestination`.
struct IPadSplitNavigationContainer: View {
    @Environment(DataStore.self) private var store
    @Environment(AppState.self) private var appState

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var sidebarSection: AppTab = .chats
    @State private var selection: AppRoute?
    @State private var searchPresented = false
    @State private var chatsModel = ChatsViewModel()
    @State private var contactsModel = ContactsViewModel()

    var body: some View {
        @Bindable var chats = chatsModel

        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 320, ideal: 350, max: 380)
        } detail: {
            IPadDetailViewRouter()
        }
        .navigationSplitViewStyle(.balanced)
        .animation(.easeInOut(duration: 0.25), value: appState.iPadDestination)
        .sheet(isPresented: $chats.showCompose) {
            ComposeView { chatID in
                chats.showCompose = false
                appState.pendingOpenChatID = chatID
            }
        }
        .onChange(of: sidebarSection) { _, section in
            // The segmented picker is the sole Settings entry point on iPad;
            // selecting it routes the detail column to the settings pane.
            if section == .settings, case .settings = appState.iPadDestination {
            } else if section == .settings {
                appState.iPadDestination = .settings(section: nil)
            }
        }
        .onChange(of: appState.pendingOpenChatID) { _, chatID in
            guard let chatID else { return }
            appState.pendingOpenChatID = nil
            // Wait out any sheet dismissal animation before routing — pushing
            // mid-dismiss is silently dropped by UIKit.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                open(chat: chatID)
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            switch newValue {
            case .chat(let chatID):
                if appState.iPadDestination != .chat(chatId: chatID) {
                    appState.iPadDestination = .chat(chatId: chatID)
                }
            case .profile(let userID):
                if appState.iPadDestination != .profile(userId: userID) {
                    appState.iPadDestination = .profile(userId: userID)
                }
            }
        }
        .onChange(of: appState.iPadDestination) { _, destination in
            syncSidebar(with: destination)
        }
        .onAppear {
            syncSidebar(with: appState.iPadDestination)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $sidebarSection) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .tag(AppTab.chats)
                    Image(systemName: "person.2.fill")
                        .tag(AppTab.contacts)
                    Image(systemName: "gearshape.fill")
                        .tag(AppTab.settings)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch sidebarSection {
                case .chats:
                    chatsSidebar
                case .contacts:
                    contactsSidebar
                case .settings:
                    settingsSidebar
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle(sidebarSection == .chats ? "Chats" : sidebarSection == .contacts ? "Contacts" : "Settings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: searchTextBinding,
                isPresented: $searchPresented,
                placement: .sidebar,
                prompt: "Search"
            )
            .toolbar {
                if sidebarSection == .chats {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            chatsModel.showCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("New message")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        searchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut("f", modifiers: .command)
                    .accessibilityLabel("Search")
                }
            }
        }
    }

    private var chatsSidebar: some View {
        List(selection: $selection) {
            ForEach(chatsModel.visibleChats(in: store)) { chat in
                ChatRowView(chat: chat)
                    .tag(AppRoute.chat(chat.id))
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .overlay {
            if store.chats.isEmpty {
                ContentUnavailableView {
                    Label("No chats yet", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Start a conversation from your contacts.")
                } actions: {
                    Button("New Message") {
                        chatsModel.showCompose = true
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private var contactsSidebar: some View {
        List(selection: $selection) {
            ForEach(contactsModel.groups(in: store), id: \.letter) { group in
                Section(group.letter) {
                    ForEach(group.users) { user in
                        contactRow(for: user)
                            .tag(AppRoute.profile(user.id))
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if contactsModel.contacts(in: store).isEmpty {
                ContentUnavailableView.search(text: contactsModel.searchText)
            }
        }
    }

    /// Pure navigation pane — the detail column already renders the full
    /// settings list, so only deep links live here (no duplicated headers).
    private var settingsSidebar: some View {
        List {
            Button {
                appState.iPadDestination = .appearance(cosmeticsSheet: true)
            } label: {
                Label("Appearance", systemImage: "paintpalette.fill")
            }
            .foregroundStyle(.primary)

            Button {
                appState.iPadDestination = .profile(userId: store.currentUserID)
            } label: {
                Label("My Profile", systemImage: "person.crop.circle.fill")
            }
            .foregroundStyle(.primary)
        }
    }

    private func contactRow(for user: User) -> some View {
        HStack(spacing: 12) {
            AvatarView(title: user.name, seed: user.id, size: 44, isOnline: user.isOnline)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }
                }
                Text(status(for: user))
                    .font(.subheadline)
                    .foregroundStyle(user.isOnline ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .padding(.vertical, 3)
    }

    private func status(for user: User) -> String {
        if user.isOnline { return "online" }
        guard store.settings.showLastSeen else { return "" }
        if let lastSeen = user.lastSeen { return lastSeen.lastSeenLabel }
        return "last seen recently"
    }

    // MARK: - Search text routing

    private var searchTextBinding: Binding<String> {
        if sidebarSection == .contacts {
            Binding(
                get: { contactsModel.searchText },
                set: { contactsModel.searchText = $0 }
            )
        } else {
            Binding(
                get: { chatsModel.searchText },
                set: { chatsModel.searchText = $0 }
            )
        }
    }

    // MARK: - Navigation helpers

    private func open(chat chatID: String) {
        sidebarSection = .chats
        if selection != .chat(chatID) {
            selection = .chat(chatID)
        }
        if appState.iPadDestination != .chat(chatId: chatID) {
            appState.iPadDestination = .chat(chatId: chatID)
        }
    }

    /// Keeps the sidebar section/selection highlight in sync when the detail
    /// destination changes from outside (notifications, compose, shortcuts).
    private func syncSidebar(with destination: IPadDetailDestination) {
        switch destination {
        case .chat(let chatId):
            sidebarSection = .chats
            if selection != .chat(chatId) {
                selection = .chat(chatId)
            }
        case .profile(let userId):
            if sidebarSection == .contacts, selection != .profile(userId) {
                selection = .profile(userId)
            }
        case .settings, .appearance:
            sidebarSection = .settings
            selection = nil
        case .emptyState:
            selection = nil
        }
    }
}

// MARK: - Detail router

/// Resolves `AppState.iPadDestination` into the detail column's content.
/// Chat destinations get their own `NavigationStack` so in-chat profile links
/// push inside the detail panel instead of disturbing the sidebar.
struct IPadDetailViewRouter: View {
    @Environment(DataStore.self) private var store
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.iPadDestination {
        case .chat(let chatId):
            NavigationStack {
                ChatView(chatID: chatId, store: store)
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
            .id(chatId)

        case .profile(let userId):
            NavigationStack {
                ProfileView(userID: userId, store: store) { chatID in
                    appState.iPadDestination = .chat(chatId: chatID)
                }
            }
            .id(userId)

        case .settings:
            NavigationStack {
                SettingsHomeView()
            }

        case .appearance:
            NavigationStack {
                CosmeticPickerSheet()
                    .navigationTitle("Appearance")
                    .navigationBarTitleDisplayMode(.inline)
            }

        case .emptyState:
            ChatDetailPlaceholderView()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .chat(let chatID):
            ChatView(chatID: chatID, store: store)
        case .profile(let userID):
            ProfileView(userID: userID, store: store) { chatID in
                appState.iPadDestination = .chat(chatId: chatID)
            }
        }
    }
}
