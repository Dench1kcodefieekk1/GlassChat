import SwiftUI
import UniformTypeIdentifiers

/// Native `UIDocumentPickerViewController` wrapper for attaching documents
/// and audio files to chat messages.
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    /// Documents, generic audio, and `.mp3` tracks.
    static var supportedTypes: [UTType] {
        [.data, .audio, .mp3]
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // `asCopy: true` hands us a local copy, so no security-scoped
        // bookmark handling is needed by the caller.
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: Self.supportedTypes,
            asCopy: true
        )
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.dismiss()
                return
            }
            parent.onPick(url)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
