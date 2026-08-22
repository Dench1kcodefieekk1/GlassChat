import SwiftUI
import UIKit

struct MessageRow: View {
    @Environment(DataStore.self) private var store
    let message: Message
    @Bindable var model: ChatViewModel

    private var isOwn: Bool { message.senderID == store.currentUserID }
    private var showSenderName: Bool { model.isGroup && !isOwn }

    static let quickReactions = ["❤️", "👍", "😂", "🔥", "😮", "😢"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOwn { Spacer(minLength: 48) }

            if showSenderName {
                AvatarView(
                    title: store.displayName(of: message),
                    seed: message.senderID,
                    size: 26
                )
            }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                if showSenderName {
                    Text(store.firstName(of: message))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                        .padding(.leading, 12)
                }
                bubble
                reactionsRow
            }

            if !isOwn { Spacer(minLength: 48) }
        }
        .padding(.vertical, 1)
    }

    // MARK: - Bubble

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let forwarded = message.forwardedFrom {
                Label("Forwarded from \(forwarded)", systemImage: "arrowshape.turn.up.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.tint))
            }

            if let reply = model.replyPreview(for: message) {
                replyPreview(for: reply)
            }

            if message.isDeleted {
                Text("Deleted message")
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            } else {
                content
            }

            metaRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 300, alignment: .leading)
        .background(bubbleBackground)
        .contextMenu { contextMenuContent }
    }

    @ViewBuilder
    private var content: some View {
        ForEach(message.attachments) { attachment in
            switch attachment.kind {
            case .image:
                StoredImageView(fileName: attachment.fileName)
                    .frame(width: 260, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        model.viewerItem = ViewerItem(fileName: attachment.fileName)
                    }
                    .accessibilityLabel("Photo")
            case .voice:
                VoiceBubble(attachment: attachment, isOwn: isOwn, playback: model.playback)
            case .file:
                if attachment.isAudioFile {
                    AudioFileBubble(attachment: attachment, isOwn: isOwn, playback: model.playback)
                } else {
                    FileBubble(attachment: attachment, isOwn: isOwn)
                }
            }
        }

        if !message.text.isEmpty {
            messageText
        }
    }

    private var messageText: some View {
        Group {
            if message.text.isEmojiOnly {
                Text(message.text)
                    .font(.system(size: 44))
            } else if let attributed = try? AttributedString(
                markdown: message.text,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
            } else {
                Text(message.text)
            }
        }
        .font(.system(size: store.settings.messageTextSize))
        .foregroundStyle(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .textSelection(.enabled)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private func replyPreview(for reply: Message) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isOwn ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(.tint))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.displayName(of: reply))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
                Text(reply.isDeleted ? "Deleted message" : (reply.text.isEmpty ? "Attachment" : reply.text))
                    .font(.caption)
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isOwn ? Color.white.opacity(0.14) : Color(uiColor: .tertiarySystemFill)),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private var metaRow: some View {
        HStack(spacing: 4) {
            if message.isEdited {
                Text("edited")
                    .font(.caption2)
            }
            Text(message.createdAt.timeLabel)
                .font(.caption2)
            if isOwn, store.settings.readReceipts {
                statusIcon
            }
        }
        .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.8)) : AnyShapeStyle(.secondary))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
        case .delivered:
            Image(systemName: "checkmark.circle")
                .font(.caption2)
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
        }
    }

    private var bubbleBackground: some View {
        let radius = store.settings.bubbleStyle.cornerRadius
        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: isOwn ? radius : 6,
            bottomTrailingRadius: isOwn ? 6 : radius,
            topTrailingRadius: radius,
            style: .continuous
        )
        .fill(isOwn
              ? AnyShapeStyle(.tint)
              : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    // MARK: - Reactions

    @ViewBuilder
    private var reactionsRow: some View {
        if !message.reactions.isEmpty {
            HStack(spacing: 4) {
                ForEach(message.reactions.keys.sorted(), id: \.self) { emoji in
                    let reactors = message.reactions[emoji] ?? []
                    Button {
                        model.toggleReaction(emoji, on: message)
                    } label: {
                        HStack(spacing: 3) {
                            Text(emoji)
                                .font(.caption)
                            if reactors.count > 1 {
                                Text("\(reactors.count)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenuContent: some View {
        HStack(spacing: 16) {
            ForEach(Self.quickReactions, id: \.self) { emoji in
                Button {
                    model.toggleReaction(emoji, on: message)
                } label: {
                    Text(emoji)
                        .font(.title3)
                }
            }
        }
        Divider()
        if !message.isDeleted {
            Button("Reply", systemImage: "arrowshape.turn.up.left") {
                model.replyTo = message
            }
            if !message.text.isEmpty {
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = message.text
                }
            }
            Button("Forward", systemImage: "arrowshape.turn.up.right") {
                model.forwardMessage = message
            }
            if let audio = message.attachments.first(where: \.isMusicAttachment) {
                Button {
                    AudioMessageActions.saveToProfileMusic(
                        attachment: audio,
                        senderName: store.displayName(of: message)
                    )
                } label: {
                    Label("Save to Profile Music", systemImage: "music.note.list")
                }
            }
            if isOwn, message.attachments.allSatisfy({ $0.kind != .image }) {
                Button("Edit", systemImage: "pencil") {
                    model.editingMessage = message
                }
            }
        }
        if isOwn {
            Button("Delete", systemImage: "trash", role: .destructive) {
                model.delete(message)
            }
        }
    }
}

// MARK: - Voice bubble

struct VoiceBubble: View {
    let attachment: Attachment
    let isOwn: Bool
    var playback: AudioPlaybackService

    private var isPlaying: Bool { playback.playingID == attachment.id }
    private var progress: Double { isPlaying ? playback.progress : 0 }

    private var samples: [Double] {
        if let waveform = attachment.waveform, !waveform.isEmpty { return waveform }
        let seed = attachment.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (0..<36).map { index in
            0.25 + 0.7 * abs(sin(Double(seed % 97) + Double(index) * 0.55))
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                playback.toggle(attachment)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isOwn ? AnyShapeStyle(.tint) : AnyShapeStyle(.white))
                    .frame(width: 34, height: 34)
                    .background(
                        isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.tint),
                        in: Circle()
                    )
            }
            .accessibilityLabel(isPlaying ? "Pause voice message" : "Play voice message")

            VStack(alignment: .leading, spacing: 3) {
                WaveformView(
                    samples: samples,
                    progress: progress,
                    active: isOwn ? .white : .accentColor,
                    inactive: isOwn ? .white.opacity(0.35) : Color(uiColor: .systemGray3)
                )
                .frame(height: 24)

                Text((attachment.duration ?? 0).durationLabel)
                    .font(.caption2)
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
            }
        }
        .padding(.vertical, 2)
    }
}

struct WaveformView: View {
    let samples: [Double]
    let progress: Double
    var active: Color
    var inactive: Color

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(samples.enumerated()), id: \.offset) { index, value in
                Capsule()
                    .fill(Double(index) / Double(max(samples.count, 1)) < progress ? active : inactive)
                    .frame(width: 2.5, height: 5 + CGFloat(value) * 19)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - File bubble

struct FileBubble: View {
    let attachment: Attachment
    let isOwn: Bool

    private var fileURL: URL { MediaService.url(for: attachment.fileName) }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isOwn
                          ? AnyShapeStyle(.white.opacity(0.22))
                          : AnyShapeStyle(Color(uiColor: .tertiarySystemFill)))
                Image(systemName: "doc.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayName ?? attachment.fileName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(attachment.fileSize ?? 0, format: .byteCount(style: .file))
                    .font(.caption)
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
            }

            ShareLink(item: fileURL) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
            }
            .accessibilityLabel("Download file")
        }
        .frame(maxWidth: 260, alignment: .leading)
    }
}
