import SwiftUI
import UIKit

struct ImageViewerView: View {
    @Environment(\.dismiss) private var dismiss
    let fileName: String

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnifyGesture.simultaneously(with: dragGesture))
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.3)) {
                            if scale > 1.5 {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .padding(12)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Close")
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            if let image {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("Photo", image: Image(uiImage: image))
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                        .padding(12)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Share photo")
                .padding()
            }
        }
        .task {
            image = ImageCache.shared.image(for: fileName)
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = lastScale * value.magnification
            }
            .onEnded { _ in
                if scale < 1 {
                    withAnimation(.spring(duration: 0.25)) {
                        scale = 1
                        offset = .zero
                    }
                    lastOffset = .zero
                }
                lastScale = scale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}
