import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
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
    var uiImage: UIImage? { UIImage(data: imageData) }
    #endif
}
