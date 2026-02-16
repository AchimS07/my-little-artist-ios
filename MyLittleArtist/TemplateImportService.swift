import Foundation

// Decodable struct matching JSON structure for drawing templates
struct TemplateJSON: Decodable {
    let id: String
    let name: String
    let category: String
    let ageMin: Int?
    let ageMax: Int?
    let svgPath: String
}

// Service to import drawing templates from a JSON file into TemplatesStore
final class TemplateImportService {
    func importFromJSONIfNeeded(store: TemplatesStore) {
        // Skip import if store already has templates; support multiple possible store APIs
        if let templates = (store as AnyObject).value(forKey: "templates") as? [Any], !templates.isEmpty {
            return
        }
        if let all = (store as AnyObject).value(forKey: "allTemplates") as? [Any], !all.isEmpty {
            return
        }
        if let count = (store as AnyObject).value(forKey: "count") as? Int, count > 0 {
            return
        }
        
        // Locate drawingTemplates.json in app bundle
        guard let url = Bundle.main.url(forResource: "drawingTemplates", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        
        let decoder = JSONDecoder()
        // Decode JSON data into array of TemplateJSON objects
        guard let items = try? decoder.decode([TemplateJSON].self, from: data) else { return }
        
        for item in items {
            // Convert category string to TemplateCategory enum, defaulting to .shapes
            let categoryEnum = TemplateCategory(rawValue: item.category) ?? .shapes
            
            // Clamp age values within 3 to 12, providing defaults if nil
            let minAge = max(3, min(12, item.ageMin ?? 6))
            let maxAge = max(3, min(12, item.ageMax ?? minAge))
            
            // Create DrawingTemplate instance from decoded data
            let template = DrawingTemplate(
                id: item.id,
                name: item.name,
                svgPath: item.svgPath,
                ageMin: minAge,
                ageMax: maxAge,
                category: categoryEnum.rawValue
            )
            
            Task { @MainActor in
                store.addTemplate(template)
            }
        }
    }
}
