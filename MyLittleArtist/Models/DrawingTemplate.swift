import Foundation

struct DrawingTemplate: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let svgPath: String
    let ageMin: Int
    let ageMax: Int
    let category: String
}

enum TemplateCategory: String, CaseIterable, Identifiable {
    case all, shapes, animals, nature, buildings, vehicles, fantasy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .shapes: return "Shapes"
        case .animals: return "Animals"
        case .nature: return "Nature"
        case .buildings: return "Buildings"
        case .vehicles: return "Vehicles"
        case .fantasy: return "Fantasy"
        }
    }

    var icon: String {
        switch self {
        case .all: return "🎨"
        case .shapes: return "⭐"
        case .animals: return "🦋"
        case .nature: return "🌸"
        case .buildings: return "🏠"
        case .vehicles: return "🚀"
        case .fantasy: return "🦄"
        }
    }
}
