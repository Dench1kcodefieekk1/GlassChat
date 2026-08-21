import SwiftUI
import UIKit

struct ImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pending: PendingImage
    let onSend: (String) -> Void
    @State private var caption = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(uiImage: pending.image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)

                TextField("Add a caption…", text: $caption, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
            }
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                        onSend(caption)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                    .accessibilityLabel("Send photo")
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct EditMessageSheet: View {
    @Environment(\.dismiss) private var dismiss
    let message: Message
    let onSave: (String) -> Void
    @State private var text: String

    init(message: Message, onSave: @escaping (String) -> Void) {
        self.message = message
        self.onSave = onSave
        _text = State(initialValue: message.text)
    }

    var body: some View {
        NavigationStack {
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(3...10)
                .padding()
                .navigationTitle("Edit message")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            dismiss()
                            onSave(text)
                        }
                        .disabled(text.trimmed.isEmpty)
                    }
                }
        }
        .presentationDetents([.height(240)])
    }
}

struct ForwardSheet: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let message: Message
    let currentChatID: String
    let onForward: (String) -> Void

    private var targets: [Chat] {
        store.chats.filter { $0.id != currentChatID }
    }

    var body: some View {
        NavigationStack {
            List(targets) { chat in
                Button {
                    dismiss()
                    onForward(chat.id)
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(
                            title: chat.title,
                            seed: chat.id,
                            symbol: chat.kind == .group ? "person.3.fill" : nil,
                            size: 42
                        )
                        Text(chat.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Forward to…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if targets.isEmpty {
                    ContentUnavailableView("No other chats", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
