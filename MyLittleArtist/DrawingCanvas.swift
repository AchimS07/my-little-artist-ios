import SwiftUI
import Photos
import UIKit

struct DrawStroke: Identifiable, Equatable {
    let id = UUID()
    var points: [CGPoint]
    var lineWidth: CGFloat
    var color: Color
    var isEraser: Bool = false

    static func == (lhs: DrawStroke, rhs: DrawStroke) -> Bool {
        // We intentionally ignore `id` for equality so identical strokes compare equal
        // Compare points, line width, color, and eraser flag
        lhs.points == rhs.points &&
        lhs.lineWidth == rhs.lineWidth &&
        lhs.color == rhs.color &&
        lhs.isEraser == rhs.isEraser
    }
}

struct DrawingCanvas: View {
    @Binding var strokes: [DrawStroke]
    @Binding var current: DrawStroke?

    var strokeColor: Color
    var lineWidth: CGFloat
    var isErasing: Bool
    var showGrid: Bool

    var maskPathTemplateSpace: Path? = nil
    var enableMasking: Bool = false
    var onStrokeCompleted: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let canvasSize = geo.size
            let scale = min(canvasSize.width, canvasSize.height) / 400.0
            let offsetX = (canvasSize.width - 400*scale)/2
            let offsetY = (canvasSize.height - 400*scale)/2
            let transform = CGAffineTransform.identity
                .translatedBy(x: offsetX, y: offsetY)
                .scaledBy(x: scale, y: scale)
            let maskPath: Path? = maskPathTemplateSpace.map { $0.applying(transform) }

            ZStack {
                Color.clear
                if showGrid {
                    GridBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Strokes layer composited together so destinationOut only affects this layer
                ZStack {
                    ForEach(strokes) { stroke in
                        exactPath(from: stroke.points)
                            .stroke(stroke.color, style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
                            .blendMode(stroke.isEraser ? .destinationOut : .normal)
                    }

                    if let cur = current {
                        exactPath(from: cur.points)
                            .stroke(cur.color.opacity(0.95), style: StrokeStyle(lineWidth: cur.lineWidth, lineCap: .round, lineJoin: .round))
                            .blendMode(cur.isEraser ? .destinationOut : .normal)
                    }
                }
                .compositingGroup()
                .mask {
                    if enableMasking, let maskPath {
                        maskPath.fill(Color.white)
                    } else {
                        Rectangle().fill(Color.white)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = value.location
                        guard !enableMasking || (maskPath?.contains(p) == true) else { return }
                        if current == nil {
                            current = DrawStroke(points: [p], lineWidth: lineWidth, color: strokeColor, isEraser: isErasing)
                        } else {
                            current?.points.append(p)
                            // Keep current stroke settings in sync if user changes tools mid-stroke
                            current?.lineWidth = lineWidth
                            current?.color = strokeColor
                            current?.isEraser = isErasing
                        }
                    }
                    .onEnded { _ in
                        if let cur = current, !cur.points.isEmpty {
                            strokes.append(cur)
                            onStrokeCompleted?()
                        }
                        current = nil
                    }
            )
        }
    }
}
private struct GridBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { ctx, _ in
                let step: CGFloat = 24
                var path = Path()
                for x in stride(from: 0, through: size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(path, with: .color(Color.secondary.opacity(0.15)), lineWidth: 0.5)
            }
            .background(Color.white)
        }
    }
}

private func exactPath(from points: [CGPoint]) -> Path {
    var path = Path()
    guard !points.isEmpty else { return path }
    if points.count == 1 {
        let p = points[0]
        path.addEllipse(in: CGRect(x: p.x - 0.5, y: p.y - 0.5, width: 1, height: 1))
        return path
    }
    path.move(to: points[0])
    for p in points.dropFirst() {
        path.addLine(to: p)
    }
    return path
}

private struct DrawingSnapshotView: View {
    let templateAsset: String?
    let strokes: [DrawStroke]
    let current: DrawStroke?
    let showGrid: Bool
    let maskPathTemplateSpace: Path?
    let enableMasking: Bool
    let canvasSize: CGSize
    let backgroundColor: Color
    var body: some View {
        let canvasSize = canvasSize
        let scale = min(canvasSize.width, canvasSize.height) / 400.0
        let offsetX = (canvasSize.width - 400*scale)/2
        let offsetY = (canvasSize.height - 400*scale)/2
        let transform = CGAffineTransform.identity
            .translatedBy(x: offsetX, y: offsetY)
            .scaledBy(x: scale, y: scale)
        let maskPath: Path? = maskPathTemplateSpace.map { $0.applying(transform) }

        ZStack {
            backgroundColor
            if showGrid {
                GridBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Template background (PDF vector from Assets.xcassets)
            if let asset = templateAsset, !asset.isEmpty {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            }

            ZStack {
                ForEach(strokes) { stroke in
                    exactPath(from: stroke.points)
                        .stroke(stroke.color, style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
                        .blendMode(stroke.isEraser ? .destinationOut : .normal)
                }
                if let cur = current {
                    exactPath(from: cur.points)
                        .stroke(cur.color.opacity(0.95), style: StrokeStyle(lineWidth: cur.lineWidth, lineCap: .round, lineJoin: .round))
                        .blendMode(cur.isEraser ? .destinationOut : .normal)
                }
            }
            .compositingGroup()
            .mask {
                if enableMasking, let maskPath {
                    maskPath.fill(Color.white)
                } else {
                    Rectangle().fill(Color.white)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
}

// MARK: - Share Sheet Wrapper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Full-screen preview with Share
struct FullScreenImagePreview: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding()

                Spacer()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [image])
                .ignoresSafeArea()
        }
    }
}

struct DrawingExporter {
    /// Renders the current drawing to a UIImage of the given size.
    /// - Parameters:
    ///   - templateAsset: Optional PDF template asset name to render beneath the strokes.
    ///   - strokes: Completed strokes to render.
    ///   - current: Current in-progress stroke (optional).
    ///   - size: Target image size in points.
    ///   - showGrid: Whether the grid background should be included.
    ///   - maskPathTemplateSpace: Optional mask path defined in 400x400 template space.
    ///   - enableMasking: If true and a mask is provided, output will be clipped to the mask.
    ///   - backgroundColor: Background color of the export (defaults to white).
    ///   - scale: Rendering scale (defaults to device screen scale).
    /// - Returns: A rendered UIImage.
    @MainActor static func renderImage(
        templateAsset: String?,
        strokes: [DrawStroke],
        current: DrawStroke?,
        size: CGSize,
        showGrid: Bool,
        maskPathTemplateSpace: Path?,
        enableMasking: Bool,
        backgroundColor: Color = .white,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let view = DrawingSnapshotView(
            templateAsset: templateAsset,
            strokes: strokes,
            current: current,
            showGrid: showGrid,
            maskPathTemplateSpace: maskPathTemplateSpace,
            enableMasking: enableMasking,
            canvasSize: size,
            backgroundColor: backgroundColor
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return uiImage
        }
        #endif
        // Fallback (should not usually be hit on iOS 16+)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let fallback = UIGraphicsImageRenderer(size: size, format: format)
        return fallback.image { ctx in
            UIColor(backgroundColor).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Saves a UIImage to the user's Photos library.
    /// Completion is delivered on the main actor so you can safely present UI (e.g., a preview or share sheet).
    @MainActor static func saveToPhotos(_ image: UIImage, completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            if let completion = completion {
                Task { @MainActor in
                    completion(success, error)
                }
            }
        }
    }
}

