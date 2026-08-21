import SwiftUI
import UIKit

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.88

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct MessageComposer: View {
    @Environment(DataStore.self) private var store
    @Bindable var model: ChatViewModel
    @FocusState private var focused: Bool

    private var hasDraft: Bool { !model.draft.trimmed.isEmpty }

    var body: some View {
        Group {
            if model.recorder.isRecording {
                recordingPanel
            } else {
                inputArea
            }
        }
        .padding(10)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .sensoryFeedback(.impact(weight: .light), trigger: model.recorder.isRecording)
    }

    // MARK: - Input

    private var inputArea: some View {
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
                HStack(spacing: 2) {
                    attachButton("photo", label: "Photo library") {
                        model.showPhotoPicker = true
                    }
                    attachButton("camera", label: "Camera") {
                        model.openCamera()
                    }
                    attachButton("paperclip", label: "Attach file") {
                        model.showFilePicker = true
                    }
                }

                TextField("Message", text: $model.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Color(uiColor: .tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .onSubmit {
                        if store.settings.enterToSend, hasDraft {
                            sendMessage()
                        }
                    }
                    .accessibilityLabel("Message text")

                micOrSend
            }
        }
    }

    private func sendMessage() {
        Haptics.medium()
        model.send()
    }

    private func attachButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(.quaternary.opacity(0.6), in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var micOrSend: some View {
        ZStack {
            if hasDraft {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                }
                .buttonStyle(PressScaleButtonStyle(scale: 0.85))
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(model.editingMessage == nil ? "Send message" : "Save edit")
            } else {
                Button {
                    Haptics.light()
                    model.startRecording()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.tint)
                        .frame(width: 38, height: 38)
                        .background(.quaternary.opacity(0.6), in: Circle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Record voice message")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasDraft)
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
        .background(
            Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    // MARK: - Recording

    private var recordingPanel: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.light()
                model.cancelRecording()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("Cancel recording")

            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .opacity(0.35 + 0.65 * abs(sin(time * 2.6)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Recording…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(model.recorder.durationLabel)
                    .font(.body.monospacedDigit())
            }

            LiveWaveform(samples: model.recorder.recentSamples)
                .frame(height: 22)
                .frame(maxWidth: .infinity)

            Button {
                Haptics.medium()
                model.sendRecording()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor, in: Circle())
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.85))
            .accessibilityLabel("Send voice message")
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -80 {
                        Haptics.light()
                        model.cancelRecording()
                    }
                }
        )
        .accessibilityHint("Swipe left to cancel recording")
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
