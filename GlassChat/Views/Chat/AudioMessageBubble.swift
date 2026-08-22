import SwiftUI
import AVFoundation
import UIKit

// MARK: - Audio attachment detection

extension Attachment {
    /// Shared `.mp3` audio files sent as file attachments.
    var isAudioFile: Bool {
        guard kind == .file else { return false }
        return (displayName ?? fileName).lowercased().hasSuffix(".mp3")
    }

    /// Voice notes and shared `.mp3` files can be saved to the profile music list.
    var isMusicAttachment: Bool {
        kind == .voice || isAudioFile
    }
}

// MARK: - Save-to-profile action for audio message bubbles

enum AudioMessageActions {
    /// Appends the chat audio attachment to the saved profile music list,
    /// persists it, and confirms with a medium haptic.
    @MainActor
    static func saveToProfileMusic(attachment: Attachment, senderName: String) {
        let track = SavedAudioTrack(
            id: UUID(),
            title: resolvedTitle(for: attachment),
            artist: senderName,
            duration: resolvedDuration(for: attachment),
            fileURL: MediaService.url(for: attachment.fileName)
        )
        MusicManager.shared.save(track)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private static func resolvedTitle(for attachment: Attachment) -> String {
        if let displayName = attachment.displayName, !displayName.isEmpty {
            return displayName
        }
        return attachment.kind == .voice ? "Voice Message" : attachment.fileName
    }

    private static func resolvedDuration(for attachment: Attachment) -> String {
        if let duration = attachment.duration, duration > 0 {
            return duration.durationLabel
        }
        let url = MediaService.url(for: attachment.fileName)
        if let player = try? AVAudioPlayer(contentsOf: url), player.duration > 0 {
            return player.duration.durationLabel
        }
        return "0:00"
    }
}

// MARK: - Inline audio file bubble

/// Telegram-style inline player for `.mp3` attachments, sharing the chat's
/// `AudioPlaybackService` with voice messages.
struct AudioFileBubble: View {
    let attachment: Attachment
    let isOwn: Bool
    var playback: AudioPlaybackService

    private var isPlaying: Bool { playback.playingID == attachment.id }
    private var progress: Double { isPlaying ? playback.progress : 0 }

    private var durationLabel: String {
        if let duration = attachment.duration, duration > 0 {
            return duration.durationLabel
        }
        return "0:00"
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
            .accessibilityLabel(isPlaying ? "Pause audio file" : "Play audio file")

            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.displayName ?? attachment.fileName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                    .lineLimit(1)

                progressBar

                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.caption2)
                    Text(durationLabel)
                        .font(.caption2.monospacedDigit())
                }
                .foregroundStyle(isOwn ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
            }
        }
        .frame(maxWidth: 260, alignment: .leading)
        .padding(.vertical, 2)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(isOwn
                      ? AnyShapeStyle(.white.opacity(0.3))
                      : AnyShapeStyle(Color(uiColor: .systemGray3)))
            Capsule()
                .fill(isOwn ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
                .scaleEffect(x: max(progress, 0.01), anchor: .leading)
        }
        .frame(height: 3)
        .animation(.linear(duration: 0.1), value: progress)
        .accessibilityHidden(true)
    }
}
