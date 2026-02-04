import Foundation

@MainActor
final class TemplatesStore: ObservableObject {
    @Published private(set) var allTemplates: [DrawingTemplate] = []
    @Published var selectedCategory: TemplateCategory = .all
    @Published var age: Int = 6

    init() {
        load()
    }

    func filteredTemplates() -> [DrawingTemplate] {
        allTemplates.filter { t in
            let matchesAge = age >= t.ageMin && age <= t.ageMax
            let matchesCategory = (selectedCategory == .all) || (t.category == selectedCategory.rawValue)
            return matchesAge && matchesCategory
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
            allTemplates = try JSONDecoder().decode([DrawingTemplate].self, from: data)
        } catch {
            assertionFailure("Failed to decode drawingTemplates.json: \(error)")
        }
    }
}
