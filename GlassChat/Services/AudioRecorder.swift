import Foundation
import AVFoundation
import Observation

struct RecordingResult {
    let url: URL
    let duration: TimeInterval
    let waveform: [Double]
}

@MainActor
@Observable
final class AudioRecorderService {
    private(set) var isRecording = false
    private(set) var duration: TimeInterval = 0
    private(set) var level: Float = 0
    private(set) var samples: [Float] = []

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?
    private var timer: Timer?

    var durationLabel: String { duration.durationLabel }
    var recentSamples: [Float] { Array(samples.suffix(26)) }

    func start() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else { return false }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("glasschat-recording-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return false }

        recorder.isMeteringEnabled = true
        recorder.record()

        self.recorder = recorder
        self.fileURL = url
        isRecording = true
        duration = 0
        samples = []

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        return true
    }

    private func tick() {
        guard let recorder else { return }
        duration = recorder.currentTime
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = max(0, min(1, (power + 55) / 55))
        level = normalized
        if samples.count < 800 {
            samples.append(normalized)
        }
    }

    func stop() -> RecordingResult? {
        guard let recorder, let url = fileURL else {
            teardown()
            return nil
        }
        recorder.stop()
        let result = RecordingResult(
            url: url,
            duration: max(duration, 0.5),
            waveform: Self.downsample(samples, to: 40).map(Double.init)
        )
        teardown()
        return result
    }

    func cancel() {
        recorder?.stop()
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        teardown()
    }

    private func teardown() {
        timer?.invalidate()
        timer = nil
        recorder = nil
        fileURL = nil
        isRecording = false
        duration = 0
        samples = []
        level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func downsample(_ samples: [Float], to count: Int) -> [Float] {
        guard !samples.isEmpty, count > 0 else {
            return Array(repeating: 0.25, count: count)
        }
        let bucket = max(1, samples.count / count)
        var result: [Float] = []
        var index = 0
        while index < samples.count, result.count < count {
            let end = min(index + bucket, samples.count)
            result.append(samples[index..<end].max() ?? 0)
            index = end
        }
        while result.count < count {
            result.append(result.last ?? 0.25)
        }
        return result
    }
}
