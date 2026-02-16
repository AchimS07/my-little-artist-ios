import SwiftUI

extension DrawingTemplate {
    var localizedNameKey: LocalizedStringKey {
        let baseId = id.replacingOccurrences(of: "shape_", with: "")
        return LocalizedStringKey("template_name_\(baseId)")
    }
}
