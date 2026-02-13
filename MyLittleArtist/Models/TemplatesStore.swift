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
            allTemplates = try JSONDecoder().decode([DrawingTemplate].self, from: data)
        } catch {
            assertionFailure("Failed to decode drawingTemplates.json: \(error)")
        }
    }
}

