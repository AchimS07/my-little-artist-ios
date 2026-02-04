import SwiftUI
import UIKit
import Photos

struct FullScreenImageViewer: View {
    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingShare = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                let size = proxy.size
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, lastScale * value)
                                }
                                .onEnded { value in
                                    lastScale = max(1.0, lastScale * value)
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            }
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(12)
                    }
                    Spacer()
                    Button {
                        showingShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(12)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingShare) {
            ActivityView(activityItems: [image])
                .ignoresSafeArea()
        }
    }
}

//struct ActivityView: UIViewControllerRepresentable {
//    let activityItems: [Any]
//    var applicationActivities: [UIActivity]? = nil
//
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
//    }
//
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}

extension DrawingExporter {
    /// Saves and returns the Photos localIdentifier for the created asset.
    static func saveToPhotosReturningLocalIdentifier(_ image: UIImage, completion: @escaping (Bool, Error?, String?) -> Void) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeholder = request.placeholderForCreatedAsset
        }) { success, error in
            let id = placeholder?.localIdentifier
            completion(success, error, id)
        }
    }

    /// Fetches a UIImage for a given Photos localIdentifier.
    static func fetchImage(localIdentifier: String, targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .aspectFit, completion: @escaping (UIImage?) -> Void) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            completion(nil)
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            completion(image)
        }
    }
}
