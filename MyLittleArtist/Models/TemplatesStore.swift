import Foundation

@MainActor
final class TemplatesStore: ObservableObject {
    @Published private(set) var allTemplates: [DrawingTemplate] = []

    func addTemplate(_ template: DrawingTemplate) {
        allTemplates.append(template)
    }

    @Published var selectedCategory: TemplateCategory = .all
    @Published var age: Int = 6
    @Published var searchText: String = ""

    init() {
        load()
    }

    func filteredTemplates() -> [DrawingTemplate] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allTemplates.filter { t in
            let matchesAge = age >= t.ageMin && age <= t.ageMax
            let matchesCategory = (selectedCategory == .all) || (t.category.lowercased() == selectedCategory.rawValue.lowercased())
            let matchesQuery: Bool
            if q.isEmpty {
                matchesQuery = true
            } else {
                let inName = t.name.lowercased().contains(q)
                let inCategory = t.category.lowercased().contains(q)
                matchesQuery = inName || inCategory
            }
            return matchesAge && matchesCategory && matchesQuery
        }
        .sorted { $0.name < $1.name }
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "drawingTemplates", withExtension: "json") else {
            assertionFailure("Missing drawingTemplates.json in bundle resources. Ensure the file is added to the app target.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            var decoded = try JSONDecoder().decode([DrawingTemplate].self, from: data)

            // Normalize decoded templates: clamp ages and normalize categories
            let validCategories = TemplateCategory.allCases.map { $0.rawValue.lowercased() }
            decoded = decoded.map { t in
                // Clamp ages to 3...12 and ensure max >= min
                let clampedMin = max(3, min(12, t.ageMin))
                let clampedMax = max(clampedMin, min(12, t.ageMax))

                // Normalize category (case-insensitive match to TemplateCategory raw values)
                let lower = t.category.lowercased()
                let matchedCategory: String
                if let matchIndex = validCategories.firstIndex(of: lower) {
                    matchedCategory = TemplateCategory.allCases[matchIndex].rawValue
                } else {
                    #if DEBUG
                    print("[TemplatesStore] Unknown category in JSON: \(t.category). Defaulting to .shapes")
                    #endif
                    matchedCategory = TemplateCategory.shapes.rawValue
                }

                return DrawingTemplate(
                    id: t.id,
                    name: t.name,
                    templateAsset: t.templateAsset,
                    ageMin: clampedMin,
                    ageMax: clampedMax,
                    category: matchedCategory
                )
            }

            allTemplates = decoded
        } catch {
            assertionFailure("Failed to decode drawingTemplates.json: \(error)")
        }
    }
}

