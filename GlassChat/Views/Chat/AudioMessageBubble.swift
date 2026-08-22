import SwiftUI
import AVFoundation
import UIKit

// MARK: - Audio attachment detection

extension Attachment {
    /// Voice notes and shared `.mp3` files can be saved to the profile music list.
    var isMusicAttachment: Bool {
        if kind == .voice { return true }
        guard kind == .file else { return false }
        return (displayName ?? fileName).lowercased().hasSuffix(".mp3")
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
