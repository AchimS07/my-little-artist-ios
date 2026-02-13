import Foundation

struct TemplateQueryIntent {
    var age: Int?
    var category: TemplateCategory?
    var keywords: [String] = []
    var prompt: String?
}

extension TemplateQueryIntent: Codable {
    private enum CodingKeys: String, CodingKey {
        case age
        case category
        case keywords
        case prompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        if let categoryString = try container.decodeIfPresent(String.self, forKey: .category) {
            category = TemplateCategory(rawValue: categoryString)
        } else {
            category = nil
        }
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(category?.rawValue, forKey: .category)
        try container.encode(keywords, forKey: .keywords)
        try container.encodeIfPresent(prompt, forKey: .prompt)
    }
}

protocol QueryUnderstandingService {
    func parse(text: String) async -> TemplateQueryIntent?
}

@MainActor
final class HeuristicQueryUnderstandingService: QueryUnderstandingService {
    func parse(text: String) async -> TemplateQueryIntent? {
        var intent = TemplateQueryIntent()
        let lc = text.lowercased()
        if let num = lc.split(whereSeparator: { !$0.isNumber }).compactMap({ Int($0) }).first {
            intent.age = min(12, max(3, num))
        }
        for c in TemplateCategory.allCases where c != .all {
            if lc.contains(c.rawValue) { intent.category = c; break }
        }
        let tokens = lc.split(whereSeparator: { !$0.isLetter })
        let stops: Set<String> = ["for","a","an","the","and","or","age","years","year","old","kids","kid"]
        intent.keywords = tokens.map(String.init).filter { !stops.contains($0) && $0.count > 2 }.prefix(5).map { $0 }
        return intent
    }
}
@MainActor
final class AIBackedQueryUnderstandingService: QueryUnderstandingService {
    private let heuristic = HeuristicQueryUnderstandingService()

    func parse(text: String) async -> TemplateQueryIntent? {
        guard #available(iOS 18.0, *) else {
            return await heuristic.parse(text: text)
        }
        do {
            // TODO: Replace with a real Foundation Models call that returns strict JSON.
            // Example shape:
            // let response = try await FoundationModels.generate(system: systemPrompt, user: text)
            // let data = Data(response.utf8)
            // let decoded = try JSONDecoder().decode(TemplateQueryIntent.self, from: data)
            // return decoded
            return await heuristic.parse(text: text)
        } catch {
            return await heuristic.parse(text: text)
        }
    }

    private var systemPrompt: String {
        """
        You are a parser. Extract a child's target age (3–12), a category from:
        {animals, vehicles, shapes, nature, buildings, fantasy}, and up to 5 keywords.
        Output strictly JSON that matches:
        { "age": Int?, "category": String?, "keywords": [String] }
        """
    }
}

// MARK: - Prompt building helper
extension TemplateQueryIntent {
    /// Builds a generation-friendly prompt from the parsed intent.
    /// Keeps things kid-friendly and simple.
    var generationPrompt: String {
        if let prompt = prompt, !prompt.isEmpty { return prompt }
        var parts: [String] = []
        if let category = category?.rawValue { parts.append(category) }
        if !keywords.isEmpty { parts.append(keywords.joined(separator: ", ")) }
        if let age = age { parts.append("for a child age \(age)") }
        let base = parts.isEmpty ? "cute coloring page" : parts.joined(separator: ", ")
        return "simple line art, bold clean outlines, high contrast, kid-friendly, \(base)"
    }
}
// MARK: - Image generation contracts
protocol ImageGenerationService {
    /// Generate an image for the given prompt. Returns PNG data.
    func generateImage(for prompt: String, size: CGSize) async throws -> Data
}

protocol TemplateRenderer {
    /// Render a nicer parametric template as PNG data for the given category/keywords.
    func renderTemplate(category: TemplateCategory?, keywords: [String], size: CGSize, strokeWidth: CGFloat) -> Data
}

