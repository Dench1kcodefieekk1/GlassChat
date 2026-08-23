import AVFoundation
import SwiftUI
import Observation

/// Plays the level-up effect and drives the 2-second celebration overlay.
///
/// Sound source: the bundled asset named `lvbel-c5-sezen-aksu` (mp3/wav/m4a)
/// when present. The repository does not ship the asset yet, so until it is
/// dropped into the bundle a short synthesized victory chime (pure PCM WAV
/// generated in code) plays instead — the effect always fires.
@MainActor
@Observable
final class LevelUpAudioNotifier {
    static let shared = LevelUpAudioNotifier()

    static let assetName = "lvbel-c5-sezen-aksu"

    /// Level being celebrated; non-nil shows the overlay for ~2 seconds.
    private(set) var celebrationLevel: Int?

    private var player: AVAudioPlayer?
    private var clearTask: Task<Void, Never>?

    func levelUp(to level: Int) {
        playLevelUpSound()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            celebrationLevel = level
        }

        clearTask?.cancel()
        clearTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self?.celebrationLevel = nil
            }
        }
    }

    // MARK: - Audio

    private func playLevelUpSound() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        for ext in ["mp3", "wav", "m4a"] {
            if let url = Bundle.main.url(forResource: Self.assetName, withExtension: ext) {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.play()
                return
            }
        }
        // Fallback: synthesized victory arpeggio (C5-E5-G5-C6).
        player = try? AVAudioPlayer(data: Self.levelUpChimeWAV())
        player?.play()
    }

    /// Builds a small 16-bit mono PCM WAV rising arpeggio with a decay
    /// envelope — no external asset required.
    static func levelUpChimeWAV() -> Data {
        let sampleRate = 22_050.0
        let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
        let noteDuration = 0.14
        let totalDuration = Double(notes.count) * noteDuration + 0.15
        let totalSamples = Int(totalDuration * sampleRate)

        var samples = [Int16](repeating: 0, count: totalSamples)
        for (noteIndex, frequency) in notes.enumerated() {
            let start = Int(Double(noteIndex) * noteDuration * sampleRate)
            let length = Int((noteDuration + 0.18) * sampleRate) // overlapping tails
            for offset in 0..<length {
                let index = start + offset
                guard index < totalSamples else { break }
                let t = Double(offset) / sampleRate
                let envelope = exp(-t * 9) * min(1, t * 220)
                let value = sin(2 * .pi * frequency * t) * 0.5 * envelope
                samples[index] = Int16(max(-1.0, min(1.0, value)) * Double(Int16.max))
            }
        }

        var data = Data()
        func append<T>(_ value: T) { withUnsafeBytes(of: value) { data.append(contentsOf: $0) } }
        func appendText(_ text: String) { data.append(contentsOf: text.utf8) }

        let byteCount = samples.count * 2
        appendText("RIFF"); append(UInt32(36 + byteCount).littleEndian); appendText("WAVE")
        appendText("fmt "); append(UInt32(16).littleEndian); append(UInt16(1).littleEndian)
        append(UInt16(1).littleEndian); append(UInt32(22_050).littleEndian)
        append(UInt32(44_100).littleEndian); append(UInt16(2).littleEndian)
        append(UInt16(16).littleEndian)
        appendText("data"); append(UInt32(byteCount).littleEndian)
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }
}

// MARK: - Celebration overlay

/// Glowing full-screen (non-blocking) banner: "LEVEL UP! You reached
/// Level X! New frames unlocked."
struct LevelUpCelebrationOverlay: View {
    let level: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("LEVEL UP!")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(.white)
                Text("You reached Level \(level)! New frames unlocked.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.55, green: 0.3, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: Color.blue.opacity(0.6), radius: 22, y: 8)
        }
        .allowsHitTesting(false)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
        .accessibilityLabel("Level up, reached level \(level)")
    }
}
