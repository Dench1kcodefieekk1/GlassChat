import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class AudioPlaybackService: NSObject, AVAudioPlayerDelegate {
    private(set) var playingID: String?
    private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func toggle(_ attachment: Attachment) {
        if playingID == attachment.id {
            stop()
            return
        }
        stop()

        let url = MediaService.url(for: attachment.fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        player.play()

        self.player = player
        playingID = attachment.id
        progress = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        playingID = nil
        progress = 0
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stop()
        }
    }
}
