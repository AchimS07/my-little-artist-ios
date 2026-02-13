import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
import ImageIO
#endif

@Model
final class SavedDrawing {
    @Attribute(.unique) var id: UUID
    var date: Date
    var templateId: String
    var templateName: String
    var imageData: Data

    init(id: UUID = UUID(), date: Date = Date(), templateId: String, templateName: String, imageData: Data) {
        self.id = id
        self.date = date
        self.templateId = templateId
        self.templateName = templateName
        self.imageData = imageData
    }

    #if canImport(UIKit)
    /// Decodes the full image safely using ImageIO to avoid partial/corrupt data issues.
    var uiImage: UIImage? {
        guard !imageData.isEmpty else { return nil }
        // First attempt: UIImage initializer (handles some formats/metadata better)
        if let img = UIImage(data: imageData) { return img }
        let cfData = imageData as CFData
        guard let src = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        // Try to create CGImage without decoding huge images eagerly
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldAllowFloat: true
        ]
        if let cgImage = CGImageSourceCreateImageAtIndex(src, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        }
        return nil
    }

    /// Fast thumbnail for grid cells; falls back to full image if thumbnail creation fails.
    var thumbnail: UIImage? {
        guard !imageData.isEmpty else { return nil }
        let maxDim: CGFloat = 512
        let cfData = imageData as CFData
        guard let src = CGImageSourceCreateWithData(cfData, nil) else { return uiImage }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDim,
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        if let cgThumb = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) {
            return UIImage(cgImage: cgThumb, scale: UIScreen.main.scale, orientation: .up)
        }
        return uiImage
    }
    #endif
}
