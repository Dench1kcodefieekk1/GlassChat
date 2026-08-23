import Foundation
import AVFoundation

// MARK: - Saved track model

struct SavedAudioTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var duration: String
    var fileURL: URL
}

// MARK: - Shared audio data manager

/// Shared music data + playback engine for the profile "Saved Music" section.
/// All mutable state is MainActor-isolated; AVAudioPlayer delegate callbacks
/// hop back to the main actor so observers only ever see consistent snapshots.
@MainActor
final class MusicManager: NSObject, ObservableObject {
    static let shared = MusicManager()

    @Published var savedTracks: [SavedAudioTrack] = []
    @Published private(set) var activeTrackID: UUID?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    private static let storageKey = "profile.savedMusicTracks"

    private override init() {
        super.init()
        loadPersistedTracks()
    }

    var activeTrack: SavedAudioTrack? {
        savedTracks.first { $0.id == activeTrackID }
    }

    func isActive(_ track: SavedAudioTrack) -> Bool {
        activeTrackID == track.id
    }

    // MARK: - Persistence

    /// Appends the track to the saved list and persists the collection locally.
    func save(_ track: SavedAudioTrack) {
        guard !savedTracks.contains(where: { $0.fileURL == track.fileURL }) else { return }
        savedTracks.append(track)
        persist()
    }

    func remove(at offsets: IndexSet) {
        let removedIDs = Set(offsets.map { savedTracks[$0].id })
        savedTracks.removeAll { removedIDs.contains($0.id) }
        if let activeID = activeTrackID, removedIDs.contains(activeID) {
            stop()
        }
        persist()
    }

    private func loadPersistedTracks() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let tracks = try? JSONDecoder().decode([SavedAudioTrack].self, from: data) else { return }
        savedTracks = tracks.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(savedTracks) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    // MARK: - Playback

    func toggle(_ track: SavedAudioTrack) {
        if isActive(track) {
            isPlaying ? pause() : resume()
        } else {
            play(track)
        }
    }

    func play(_ track: SavedAudioTrack) {
        guard FileManager.default.fileExists(atPath: track.fileURL.path),
              let newPlayer = try? AVAudioPlayer(contentsOf: track.fileURL) else { return }

        stop()

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        newPlayer.delegate = self
        newPlayer.play()

        player = newPlayer
        activeTrackID = track.id
        isPlaying = true
        progress = 0
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func resume() {
        guard let player, !player.isPlaying else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func stop() {
        stopTimer()
        player?.stop()
        player = nil
        activeTrackID = nil
        isPlaying = false
        progress = 0
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else { return }
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func playNextAfterFinish() {
        guard let activeID = activeTrackID,
              let index = savedTracks.firstIndex(where: { $0.id == activeID }),
              index + 1 < savedTracks.count else {
            stop()
            return
        }
        play(savedTracks[index + 1])
    }
}

// MARK: - AVAudioPlayerDelegate

extension MusicManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playNextAfterFinish()
        }
    }
}
