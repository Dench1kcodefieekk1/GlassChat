import SwiftUI
import UIKit

struct MessageInputBar: View {
    @Environment(DataStore.self) private var store
    @Bindable var model: ChatViewModel
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if model.recorder.isRecording {
                recordingBar
            } else {
                inputBar
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(spacing: 8) {
            if let reply = model.replyTo {
                banner(
                    title: "Replying to \(store.displayName(of: reply))",
                    detail: reply.text.isEmpty ? "Attachment" : reply.text
                ) {
                    model.replyTo = nil
                }
            }
            if let editing = model.editingMessage {
                banner(title: "Editing message", detail: editing.text) {
                    model.cancelEditing()
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle.angled") {
                        model.showPhotoPicker = true
                    }
                    if model.isCameraAvailable {
                        Button("Camera", systemImage: "camera") {
                            model.showCamera = true
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                }
                .accessibilityLabel("Add attachment")

                TextField("Message", text: $model.draft, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .onSubmit {
                        if store.settings.enterToSend {
                            model.send()
                        }
                    }
                    .accessibilityLabel("Message text")

                if model.draft.trimmed.isEmpty {
                    Button {
                        model.startRecording()
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.tint)
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("Record voice message")
                } else {
                    Button {
                        model.send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.tint)
                    }
                    .accessibilityLabel(model.editingMessage == nil ? "Send message" : "Save edit")
                }
            }
        }
    }

    private func banner(title: String, detail: String, onCancel: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.tint)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Cancel")
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Recording

    private var recordingBar: some View {
        HStack(spacing: 14) {
            Button {
                model.cancelRecording()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Cancel recording")

            Spacer()

            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .opacity(0.35 + 0.65 * abs(sin(time * 2.6)))
            }

            Text(model.recorder.durationLabel)
                .font(.body.monospacedDigit())

            LiveWaveform(samples: model.recorder.recentSamples)
                .frame(height: 22)

            Spacer()

            Button {
                model.sendRecording()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
            }
            .accessibilityLabel("Send voice message")
        }
    }
}

struct LiveWaveform: View {
    let samples: [Float]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, value in
                Capsule()
                    .fill(.tint)
                    .frame(width: 2.5, height: 4 + CGFloat(value) * 18)
            }
        }
        .animation(.linear(duration: 0.08), value: samples.count)
    }
}
