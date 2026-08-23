import SwiftUI
import UIKit
import PhotosUI

struct ChatView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: ChatViewModel
    @State private var showWalletApp = false
    @State private var showFragmentApp = false
    private let verification = VerificationManager.shared

    init(chatID: String, store: DataStore) {
        _model = State(initialValue: ChatViewModel(chatID: chatID, store: store))
    }

    var body: some View {
        messageList
            .safeAreaInset(edge: .top, spacing: 0) {
                chatHeader
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(false)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(ChatWallpaperView(wallpaper: store.settings.wallpaper).ignoresSafeArea())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear { model.activate() }
            .onDisappear { model.deactivate() }
            .onChange(of: verification.pendingPillID) { _, pillID in
                guard let pillID, verification.celebrationChatID == model.chatID else { return }
                model.triggerConfetti(for: pillID)
            }
            .onChange(of: store.sortedMessages(for: model.chatID).count) { oldValue, newValue in
                model.markReadIfActive()
                // Auto-scroll to the newest message whenever one is appended
                // (sent or received).
                if newValue > oldValue {
                    model.scrollTrigger += 1
                }
            }
            .photosPicker(isPresented: $model.showPhotoPicker,
                          selection: $model.pickerItem,
                          matching: .images)
            .onChange(of: model.pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        model.pendingImage = PendingImage(image: image)
                    }
                    model.pickerItem = nil
                }
            }
            .sheet(isPresented: $model.showFilePicker) {
                DocumentPicker { url in
                    model.attachFile(at: url)
                }
            }
            .sheet(item: $model.pendingImage) { pending in
                ImagePreviewSheet(pending: pending) { caption in
                    model.sendImage(pending, caption: caption)
                }
            }
            .sheet(isPresented: $model.showAttachmentSheet) {
                AttachmentSheet(model: model)
            }
            .fullScreenCover(isPresented: $model.showCamera) {
                CameraPicker { image in
                    model.pendingImage = PendingImage(image: image)
                }
                .ignoresSafeArea()
            }
            .sheet(item: $model.editingMessage) { message in
                EditMessageSheet(message: message) { newText in
                    model.applyEdit(message, newText)
                }
            }
            .sheet(item: $model.forwardMessage) { message in
                ForwardSheet(message: message, currentChatID: model.chatID) { targetChatID in
                    model.forward(message, to: targetChatID)
                }
            }
            .fullScreenCover(item: $model.viewerItem) { item in
                ImageViewerView(fileName: item.fileName)
            }
            .overlay {
                if model.showConfetti {
                    ConfettiBurstView(
                        origin: model.pillFrame.map { CGPoint(x: $0.midX, y: $0.midY) }
                            ?? CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height * 0.72)
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: model.showConfetti)
            .overlay(alignment: .bottom) {
                if model.isWalletChat {
                    miniAppPill("👛 Open Wallet Mini App") { showWalletApp = true }
                } else if model.isFragmentChat {
                    miniAppPill("🌐 Open Fragment Mini App") { showFragmentApp = true }
                }
            }
            .sheet(isPresented: $showWalletApp) {
                WalletMiniAppView()
            }
            .sheet(isPresented: $showFragmentApp) {
                FragmentMiniAppView()
            }
            .alert("Microphone access needed", isPresented: $model.recordingDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable microphone access in Settings to record voice messages.")
            }
            .alert("Camera Unavailable", isPresented: $model.cameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Camera is unavailable on this device.")
            }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.88))
            .accessibilityLabel("Back")

            Spacer(minLength: 0)

            header

            Spacer(minLength: 0)

            moreMenu
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var header: some View {
        if let profileUserID = model.profileUserID {
            NavigationLink(value: AppRoute.profile(profileUserID)) {
                headerContent
            }
            .buttonStyle(.plain)
        } else {
            headerContent
        }
    }

    private var headerContent: some View {
        HStack(spacing: 10) {
            AvatarView(
                title: model.title,
                seed: model.chatID,
                symbol: model.isGroup ? "person.3.fill" : nil,
                size: 36,
                isOnline: model.otherUser?.isOnline == true
            )
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(model.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if model.otherUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Verified")
                    }
                }
                if model.isTyping {
                    HStack(spacing: 5) {
                        Text("typing")
                            .font(.caption)
                            .foregroundStyle(.tint)
                        TypingDotsView(dotColor: .accentColor, dotSize: 3.5)
                    }
                } else {
                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.isTyping)
    }

    @ViewBuilder
    private var moreMenu: some View {
        Menu {
            if let chat = model.chat {
                Button(chat.isMuted ? "Unmute" : "Mute",
                       systemImage: chat.isMuted ? "bell" : "bell.slash") {
                    store.toggleMute(chat)
                }
                Button(chat.isPinned ? "Unpin" : "Pin",
                       systemImage: chat.isPinned ? "pin.slash" : "pin") {
                    store.togglePin(chat)
                }
            }
            Button("Mark as Read", systemImage: "checkmark") {
                store.markAllRead(model.chatID)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .accessibilityLabel("Chat options")
    }

    // MARK: - Mini app launcher

    /// Persistent launcher pill pinned above the composer in system bot chats.
    private func miniAppPill(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular.interactive(), in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
        .padding(.bottom, 74)
        .accessibilityLabel(title)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(model.rows()) { item in
                        row(for: item)
                            .id(item.id)
                    }
                }
                .padding(.horizontal, AppTheme.chatHorizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.8),
                           value: store.sortedMessages(for: model.chatID).count)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let distance = geometry.contentSize.height + geometry.contentInsets.bottom
                    - geometry.contentOffset.y - geometry.containerSize.height
                return distance < 140
            } action: { _, isNear in
                model.isNearBottom = isNear
                if isNear { model.pendingIncoming = 0 }
            }
            .safeAreaInset(edge: .bottom) {
                MessageComposer(model: model)
            }
            .overlay(alignment: .bottom) {
                if model.pendingIncoming > 0 && !model.isNearBottom {
                    newMessagesButton(proxy: proxy)
                        .padding(.bottom, 92)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: model.pendingIncoming)
            .onChange(of: model.scrollTrigger) {
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: model.sendScrollTrigger) {
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onAppear {
                DispatchQueue.main.async {
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let last = model.rows().last else { return }
        if animated {
            withAnimation(.spring(duration: 0.35)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func newMessagesButton(proxy: ScrollViewProxy) -> some View {
        Button {
            model.pendingIncoming = 0
            scrollToBottom(proxy: proxy, animated: true)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.footnote.weight(.bold))
                Text("New messages")
                    .font(.footnote.weight(.semibold))
                UnreadBadge(count: model.pendingIncoming, muted: false)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .accessibilityLabel("Scroll to new messages")
    }

    @ViewBuilder
    private func row(for item: ChatRowItem) -> some View {
        switch item.kind {
        case .day(let title):
            DaySeparator(title: title)
        case .unreadSeparator:
            UnreadSeparator()
        case .typing:
            TypingBubble()
        case .message(let message):
            if message.isSystemPill {
                VerifiedGiftPill(text: message.text) { rect in
                    model.reportCelebrationPillFrame(rect)
                }
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else {
                MessageRow(message: message, model: model)
                    .transition(.asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 0.96, anchor: .bottom))
                            .combined(with: .offset(y: 8)),
                        removal: .opacity
                            .combined(with: .scale(scale: 0.96, anchor: .bottom))
                    ))
            }
        }
    }
}

// MARK: - Separators and indicators

struct DaySeparator: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

struct UnreadSeparator: View {
    var body: some View {
        HStack(spacing: 10) {
            separatorLine
            Text("Unread messages")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            separatorLine
        }
        .padding(.vertical, 8)
        .accessibilityAddTraits(.isHeader)
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(.tint.opacity(0.3))
            .frame(height: 1)
    }
}

struct TypingBubble: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TypingDotsView(dotColor: Color(uiColor: .secondaryLabel), dotSize: 7)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                )
            Spacer(minLength: 48)
        }
        .accessibilityLabel("Contact is typing")
    }
}
