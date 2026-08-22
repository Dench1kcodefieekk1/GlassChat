import SwiftUI
import UIKit
import PhotosUI

struct UserProfileView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppState.self) private var appState
    @AppStorage("userPhone") private var userPhone = "+380 99 123 4567"
    @State private var showCompose = false
    @State private var showCall = false
    @State private var toast: String?
    @State private var mediaTab: ProfileMediaTab = .media
    @State private var viewerItem: ViewerItem?
    @State private var bannerPickerItem: PhotosPickerItem?
    @State private var photoExpanded = false
    @Namespace private var avatarNamespace

    private var me: User { store.currentUser }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    VStack(spacing: 20) {
                        actions
                        infoCard
                        verifiedSubtitle
                        mediaSection
                        ProfileMusicSection()
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EditProfileView(userID: store.currentUserID)
                    } label: {
                        Text("Edit")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel("Edit profile")
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView { userID in
                    showCompose = false
                    appState.selectedTab = .chats
                    appState.pendingOpenChatID = store.createDirectChat(with: userID).id
                }
            }
            .fullScreenCover(isPresented: $showCall) {
                SimulatedCallView(user: me)
            }
            .fullScreenCover(item: $viewerItem) { item in
                ImageViewerView(fileName: item.fileName)
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast)
            .onChange(of: bannerPickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        setBanner(image)
                    }
                    bannerPickerItem = nil
                }
            }

            if photoExpanded {
                expandedPhotoOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottom) {
                bannerWithPicker

                avatar
                    .offset(y: 54)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            photoExpanded = true
                        }
                    }
                    .accessibilityLabel("Expand profile photo")
            }
            .padding(.bottom, 54)

            HStack(spacing: 6) {
                Text(me.name)
                    .font(.title2.weight(.semibold))
                if me.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Verified")
                }
            }
            Text("online")
                .font(.subheadline)
                .foregroundStyle(.tint)
            Text("@\(me.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Banner with a small glass camera badge for setting a custom image;
    /// tapping the banner previews it full screen (avatar zoom otherwise).
    private var bannerWithPicker: some View {
        StretchyProfileBanner(user: me)
            .overlay(alignment: .topTrailing) {
                PhotosPicker(selection: $bannerPickerItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
                .accessibilityLabel("Set profile banner")
            }
            .onTapGesture {
                if let bannerFile = me.bannerFileName {
                    viewerItem = ViewerItem(fileName: bannerFile)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        photoExpanded = true
                    }
                }
            }
    }

    /// The avatar carries the matched geometry id only while collapsed.
    private var avatar: some View {
        ZStack {
            if photoExpanded {
                AvatarView(title: me.name, seed: me.id, size: 108, isOnline: true, fileName: me.avatarFileName)
            } else {
                AvatarView(title: me.name, seed: me.id, size: 108, isOnline: true, fileName: me.avatarFileName)
                    .matchedGeometryEffect(id: "my-avatar", in: avatarNamespace)
            }
        }
    }

    // MARK: - Expanded photo (Telegram-style)

    private var expandedPhotoOverlay: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Group {
                    if let avatarFile = me.avatarFileName {
                        StoredImageView(fileName: avatarFile)
                            .frame(width: 300, height: 300)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                    } else {
                        AvatarView(title: me.name, seed: me.id, size: 260, fileName: me.avatarFileName)
                    }
                }
                .matchedGeometryEffect(id: "my-avatar", in: avatarNamespace)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(me.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        if me.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.body)
                                .foregroundStyle(.tint)
                        }
                    }
                    Text("@\(me.username)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .zIndex(10)
        .transition(.opacity)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                photoExpanded = false
            }
        }
    }

    private func setBanner(_ image: UIImage) {
        Haptics.light()
        let scaled = MediaService.downscale(image, maxDimension: 1600)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return }
        var user = me
        if let old = user.bannerFileName {
            MediaService.delete(old)
        }
        user.bannerFileName = MediaService.save(data, extension: "jpg")
        store.users[user.id] = user
        store.save()
        showToast("Banner updated")
    }

    @ViewBuilder
    private var verifiedSubtitle: some View {
        if me.isVerified {
            Text("Verified by Verification")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: 24) {
            GlassActionButton(title: "Message", systemImage: "bubble.fill") {
                Haptics.light()
                showCompose = true
            }
            GlassActionButton(title: "Call", systemImage: "phone.fill") {
                guard store.settings.allowCalls else {
                    showToast("Calls are disabled in Privacy")
                    return
                }
                Haptics.light()
                showCall = true
            }
            GlassActionButton(title: "Video", systemImage: "video.fill") {
                guard store.settings.allowCalls else {
                    showToast("Calls are disabled in Privacy")
                    return
                }
                Haptics.light()
                showCall = true
            }
            GlassActionButton(title: "Search", systemImage: "magnifyingglass") {
                Haptics.light()
                appState.selectedTab = .chats
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "phone.fill", color: .green, title: userPhone, subtitle: "Phone", copyable: true)
            divider
            infoRow(icon: "at", color: .orange, title: "@\(me.username)", subtitle: "Username", copyable: true)
            if !me.bio.isEmpty {
                divider
                infoRow(icon: "info.circle.fill", color: .blue, title: me.bio, subtitle: "Bio", copyable: false)
            }
            divider
            infoRow(
                icon: "calendar",
                color: .purple,
                title: me.registrationDateLabel,
                subtitle: "Registration Date",
                copyable: false
            )
            divider
            infoRow(icon: "number", color: .gray, title: me.id, subtitle: "User ID", copyable: true)
            if let channel = me.linkedChannel {
                divider
                infoRow(icon: "megaphone.fill", color: .purple, title: channel, subtitle: "Linked Channel", copyable: false)
            }
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var divider: some View {
        Divider().padding(.leading, 52)
    }

    private func infoRow(icon: String, color: Color, title: String, subtitle: String, copyable: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.body)
                    .textSelection(.enabled)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if copyable {
                Button {
                    copy(title, label: subtitle)
                } label: {
                    Text("Copy")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
                .accessibilityLabel("Copy \(subtitle)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func copy(_ value: String, label: String) {
        UIPasteboard.general.string = value
        Haptics.light()
        showToast("\(label) copied")
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if toast == message { toast = nil }
        }
    }

    // MARK: - Shared media

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared Media")
                .font(.headline)

            Picker("Media type", selection: $mediaTab) {
                ForEach(ProfileMediaTab.allCases) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch mediaTab {
            case .media:
                mediaGrid
            case .files:
                filesList
            case .links:
                linksList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var myMedia: [SharedMediaItem] {
        var result: [SharedMediaItem] = []
        for chat in store.chats {
            for message in store.sortedMessages(for: chat.id)
            where message.senderID == store.currentUserID && !message.isDeleted {
                for attachment in message.attachments where attachment.kind == .image {
                    result.append(SharedMediaItem(message: message, attachment: attachment))
                }
            }
        }
        return result.reversed()
    }

    private var myFiles: [SharedMediaItem] {
        var result: [SharedMediaItem] = []
        for chat in store.chats {
            for message in store.sortedMessages(for: chat.id)
            where message.senderID == store.currentUserID && !message.isDeleted {
                for attachment in message.attachments where attachment.kind == .file {
                    result.append(SharedMediaItem(message: message, attachment: attachment))
                }
            }
        }
        return result.reversed()
    }

    private var myLinks: [String] {
        var links: [String] = []
        for chat in store.chats {
            for message in store.sortedMessages(for: chat.id)
            where message.senderID == store.currentUserID && !message.isDeleted {
                for match in message.text.matches(of: /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/) {
                    links.append(String(match.output.2))
                }
            }
        }
        return links
    }

    @ViewBuilder
    private var mediaGrid: some View {
        let media = myMedia
        if media.isEmpty {
            mediaEmptyState("No photos sent yet", symbol: "photo.stack")
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(media) { item in
                    StoredImageView(fileName: item.attachment.fileName)
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onTapGesture {
                            viewerItem = ViewerItem(fileName: item.attachment.fileName)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var filesList: some View {
        let files = myFiles
        if files.isEmpty {
            mediaEmptyState("No files sent yet", symbol: "folder")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(files.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.tint)
                            .frame(width: 30)
                        Text(item.attachment.displayName ?? item.attachment.fileName)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(item.message.createdAt.chatListLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    if index < files.count - 1 { Divider() }
                }
            }
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
    }

    @ViewBuilder
    private var linksList: some View {
        let links = myLinks
        if links.isEmpty {
            mediaEmptyState("No links sent yet", symbol: "link")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .foregroundStyle(.tint)
                            .frame(width: 30)
                        Text(link)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    if index < links.count - 1 { Divider() }
                }
            }
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
    }

    private func mediaEmptyState(_ title: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

enum ProfileMediaTab: String, CaseIterable, Identifiable {
    case media
    case files
    case links

    var id: String { rawValue }

    var label: String {
        switch self {
        case .media: return "Media"
        case .files: return "Files"
        case .links: return "Links"
        }
    }
}
