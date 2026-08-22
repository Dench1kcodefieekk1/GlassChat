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

            if model.recorder.isRecording {
                recordingPanel
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    attachmentButton
                    inputField
                    actionButton
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .sensoryFeedback(.impact(weight: .light), trigger: model.recorder.isRecording)
    }

    // MARK: - Attachment

    private var attachmentButton: some View {
        Button {
            Haptics.light()
            model.showFilePicker = true
        } label: {
            Image(systemName: "paperclip")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.9))
        .onLongPressGesture(minimumDuration: 0.45) {
            Haptics.light()
            model.showAttachmentSheet = true
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("Attach file or audio")
        .accessibilityHint("Touch and hold for photos and camera")
    }

    // MARK: - Input field

    private var inputField: some View {
        HStack(alignment: .bottom, spacing: 4) {
            TextField("Message", text: $model.draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($focused)
                .onSubmit {
                    if store.settings.enterToSend, hasDraft {
                        sendMessage()
                    }
                }
                .accessibilityLabel("Message text")

            Button {
                Haptics.light()
                focused = true
            } label: {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.85))
            .accessibilityLabel("Emoji")
        }
        .padding(.leading, 15)
        .padding(.trailing, 8)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
    }

    // MARK: - Mic / Send

    private var actionButton: some View {
        ZStack {
            if hasDraft {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(PressScaleButtonStyle(scale: 0.88))
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
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(PressScaleButtonStyle(scale: 0.9))
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Record voice message")
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: hasDraft)
        .glassEffect(
            hasDraft ? .regular.tint(.accentColor) : .regular.interactive(),
            in: Circle()
        )
    }

    private func sendMessage() {
        Haptics.medium()
        model.send()
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
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.88))
            .glassEffect(.regular.tint(.accentColor), in: Circle())
            .accessibilityLabel("Send voice message")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
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

// MARK: - Attachment sheet

struct AttachmentSheet: View {
    @Bindable var model: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            Text("Attach")
                .font(.headline)

            VStack(spacing: 8) {
                option(symbol: "photo.on.rectangle", title: "Photo or Video", tint: .blue) {
                    model.showPhotoPicker = true
                }
                option(symbol: "camera", title: "Camera", tint: .red) {
                    model.openCamera()
                }
                option(symbol: "folder", title: "File", tint: .orange) {
                    model.showFilePicker = true
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 8)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
    }

    private func option(symbol: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                action()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(tint.gradient, in: Circle())
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
    }
}
