import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(DataStore.self) private var store
    @State private var model: ProfileViewModel
    @State private var showCall = false
    @State private var viewerItem: ViewerItem?

    let onOpenChat: ((String) -> Void)?

    init(userID: String, store: DataStore, onOpenChat: ((String) -> Void)? = nil) {
        _model = State(initialValue: ProfileViewModel(userID: userID, store: store))
        self.onOpenChat = onOpenChat
    }

    var body: some View {
        ScrollView {
            if let user = model.user {
                VStack(spacing: 20) {
                    header(for: user)
                    actions
                    infoCard(for: user)
                    mediaSection
                }
                .padding()
            } else {
                ContentUnavailableView("User not found", systemImage: "person.crop.circle.badge.exclamationmark")
                    .padding(.top, 60)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCall) {
            SimulatedCallView(user: model.user)
        }
        .fullScreenCover(item: $viewerItem) { item in
            ImageViewerView(fileName: item.fileName)
        }
    }

    // MARK: - Sections

    private func header(for user: User) -> some View {
        VStack(spacing: 10) {
            AvatarView(title: user.name, seed: user.id, size: 108, isOnline: user.isOnline)
            HStack(spacing: 6) {
                Text(user.name)
                    .font(.title2.weight(.semibold))
                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Verified")
                }
            }
            Text("@\(user.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !model.statusText.isEmpty {
                Text(model.statusText)
                    .font(.subheadline)
                    .foregroundStyle(user.isOnline ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        HStack(spacing: 24) {
            if !model.isSelf {
                GlassActionButton(title: "Message", systemImage: "bubble.fill") {
                    let chatID = model.openChat()
                    onOpenChat?(chatID)
                }
                GlassActionButton(title: "Call", systemImage: "phone.fill") {
                    showCall = true
                }
            }
            GlassActionButton(
                title: model.isMuted ? "Unmute" : "Mute",
                systemImage: model.isMuted ? "bell" : "bell.slash.fill"
            ) {
                model.toggleMute()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func infoCard(for user: User) -> some View {
        VStack(spacing: 0) {
            if !user.bio.isEmpty {
                infoRow(icon: "info.circle.fill", color: .blue, title: user.bio, subtitle: "Bio")
                divider
            }
            infoRow(icon: "at", color: .orange, title: "@\(user.username)", subtitle: "Username")
            divider
            infoRow(icon: "phone.fill", color: .green, title: user.phone, subtitle: "Phone")
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var divider: some View {
        Divider().padding(.leading, 52)
    }

    private func infoRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var mediaSection: some View {
        let media = model.sharedImages
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared Media")
                .font(.headline)
            if media.isEmpty {
                Text("No shared photos yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SimulatedCallView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(uiColor: .systemIndigo).opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()
                if let user {
                    TimelineView(.animation) { context in
                        let time = context.date.timeIntervalSinceReferenceDate
                        AvatarView(title: user.name, seed: user.id, size: 110)
                            .padding(8 + 4 * abs(sin(time * 1.8)))
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    Text(user.name)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Calling…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Calls are simulated in this local prototype.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(.red, in: Circle())
                }
                .accessibilityLabel("End call")
                .padding(.bottom, 40)
            }
        }
    }
}
