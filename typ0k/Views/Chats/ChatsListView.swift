import SwiftUI

struct ChatsListView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppState.self) private var appState
    @Bindable var model: ChatsViewModel

    private var chats: [Chat] { model.visibleChats(in: store) }
    private var matches: [Message] { model.messageMatches(in: store) }

    var body: some View {
        Group {
            if chats.isEmpty && !isSearching {
                emptyState
            } else if isSearching && chats.isEmpty && matches.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            } else {
                list
            }
        }
        .navigationTitle("Chats")
        .searchable(text: $model.searchText, prompt: "Search chats and messages")
        .task {
            ChatService.shared.startChatListListener()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New message")
            }
        }
        .sheet(isPresented: $model.showCompose) {
            ComposeView { chatID in
                model.showCompose = false
                appState.pendingOpenChatID = chatID
            }
        }
    }

    private var isSearching: Bool {
        !model.searchText.trimmed.isEmpty
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No chats yet", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a conversation from your contacts.")
        } actions: {
            Button("New Message") {
                model.showCompose = true
            }
            .buttonStyle(.glassProminent)
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(chats) { chat in
                    chatRow(for: chat)
                }
            }
            if !matches.isEmpty {
                Section("Messages") {
                    ForEach(matches) { message in
                        Button {
                            model.openChat(message.chatID)
                        } label: {
                            messageMatchRow(for: message)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .refreshable {
            try? await Task.sleep(for: .seconds(0.8))
        }
    }

    @ViewBuilder
    private func chatRow(for chat: Chat) -> some View {
        NavigationLink(value: AppRoute.chat(chat.id)) {
            ChatRowView(chat: chat)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteChat(chat.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                store.togglePin(chat)
            } label: {
                Label(chat.isPinned ? "Unpin" : "Pin", systemImage: chat.isPinned ? "pin.slash" : "pin")
            }
            .tint(.accentColor)

            if chat.unreadCount > 0 {
                Button {
                    store.markAllRead(chat.id)
                } label: {
                    Label("Read", systemImage: "checkmark")
                }
                .tint(.green)
            }
        }
        .contextMenu {
            Button(chat.isPinned ? "Unpin" : "Pin", systemImage: chat.isPinned ? "pin.slash" : "pin") {
                store.togglePin(chat)
            }
            Button(chat.isMuted ? "Unmute" : "Mute", systemImage: chat.isMuted ? "bell" : "bell.slash") {
                store.toggleMute(chat)
            }
            Button("Mark as Read", systemImage: "checkmark") {
                store.markAllRead(chat.id)
            }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                store.deleteChat(chat.id)
            }
        }
    }

    @ViewBuilder
    private func messageMatchRow(for message: Message) -> some View {
        let chat = store.chat(id: message.chatID)
        HStack(spacing: 12) {
            AvatarView(
                title: chat?.title ?? "",
                seed: message.chatID,
                symbol: chat?.kind == .group ? "person.3.fill" : nil,
                size: 40
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(chat?.title ?? "")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(message.createdAt.chatListLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ChatRowView: View {
    @Environment(DataStore.self) private var store
    let chat: Chat

    private var otherUser: User? { store.otherUser(in: chat) }
    private var isTyping: Bool { store.typingChatIDs.contains(chat.id) }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                title: chat.title,
                seed: chat.id,
                symbol: chat.kind == .group ? "person.3.fill" : nil,
                size: 54,
                isOnline: otherUser?.isOnline == true
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)
                    if otherUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Verified")
                    }
                    Spacer()
                    if let date = chat.lastMessageAt {
                        Text(date.chatListLabel)
                            .font(.caption)
                            .foregroundStyle(chat.unreadCount > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }
                }

                HStack(spacing: 6) {
                    preview
                        .lineLimit(1)
                    Spacer()
                    trailingIcons
                }
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var preview: some View {
        if isTyping {
            HStack(spacing: 5) {
                Text("typing")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                TypingDotsView(dotColor: .accentColor, dotSize: 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Someone is typing")
        } else if !store.settings.messagePreviews {
            Text("Message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            let prefix = chat.kind == .group ? senderPrefix : ""
            Text(prefix + chat.lastMessagePreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var senderPrefix: String {
        guard let last = store.lastMessage(for: chat.id), last.senderID != store.currentUserID else {
            return ""
        }
        return "\(store.firstName(of: last)): "
    }

    @ViewBuilder
    private var trailingIcons: some View {
        if chat.isMuted {
            Image(systemName: "bell.slash.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if chat.isPinned {
            Image(systemName: "pin.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if chat.unreadCount > 0 {
            UnreadBadge(count: chat.unreadCount, muted: chat.isMuted)
        }
    }
}
