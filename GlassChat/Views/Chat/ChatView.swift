import SwiftUI
import UIKit
import PhotosUI

struct ChatView: View {
    @Environment(DataStore.self) private var store
    @State private var model: ChatViewModel

    init(chatID: String, store: DataStore) {
        _model = State(initialValue: ChatViewModel(chatID: chatID, store: store))
    }

    var body: some View {
        messageList
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    header
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .onAppear { model.activate() }
            .onDisappear { model.deactivate() }
            .onChange(of: store.sortedMessages(for: model.chatID).count) {
                model.markReadIfActive()
                model.scrollTrigger += 1
            }
            .sensoryFeedback(.impact(weight: .light), trigger: model.scrollTrigger)
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
            .sheet(item: $model.pendingImage) { pending in
                ImagePreviewSheet(pending: pending) { caption in
                    model.sendImage(pending, caption: caption)
                }
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
            .alert("Microphone access needed", isPresented: $model.recordingDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable microphone access in Settings to record voice messages.")
            }
    }

    // MARK: - Header

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
                Text(model.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(model.isTyping ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
            }
        }
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
                .animation(.spring(duration: 0.3), value: model.scrollTrigger)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                MessageInputBar(model: model)
            }
            .onChange(of: model.scrollTrigger) {
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
            MessageRow(message: message, model: model)
                .transition(.opacity)
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
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 7, height: 7)
                            .opacity(0.35 + 0.65 * abs(sin(time * 3 + Double(index) * 0.9)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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
            }
            Spacer(minLength: 48)
        }
        .accessibilityLabel("Contact is typing")
    }
}
