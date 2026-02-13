import SwiftUI
import SwiftData
import UIKit

struct TemplatesView: View {
    @StateObject private var store = TemplatesStore()
    @Environment(\.modelContext) private var modelContext
    @Query var profiles: [UserProfile]
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    @State private var searchText: String = ""
    @State private var showingCreateTemplate: Bool = false
    @State private var createPrompt: String = ""
    @State private var useAppleIntelligence: Bool = true
    @State private var aiSVG: String? = nil
    @State private var isGenerating: Bool = false
    private let imageGenerator: ImageGenerationService = AIImageGenerationService()
    private let templateRenderer: TemplateRenderer = CompositeTemplateRenderer()
    private let queryService: QueryUnderstandingService = AIBackedQueryUnderstandingService()

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            contentList
                .scrollContentBackground(.hidden)
        }
        .task { updateAgeFromActiveProfile() }
        .onChange(of: activeProfileStore.activeProfile) { _, newValue in
            if let p = newValue { store.age = p.age }
        }
        .navigationTitle("app_title")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("search_prompt"))
        .onSubmit(of: .search) { handleSearchSubmit() }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                // No action on clearing search text
            }
        }
        .toolbar { addTemplateToolbar }
        .sheet(isPresented: $showingCreateTemplate) { createTemplateSheet }
    }

    private var backgroundGradient: LinearGradient {
        let backgroundColors: [Color] = [Color(red: 1.0, green: 0.95, blue: 0.8), Color(red: 0.9, green: 0.95, blue: 1.0)]
        return LinearGradient(colors: backgroundColors, startPoint: .top, endPoint: .bottom)
    }

    private var contentList: some View {
        List {
            headerSection
            templatesSection
        }
    }

    private var headerSection: some View {
        Section {
            ageHeader
            categoryScroller
        }
    }

    private var ageHeader: some View {
        HStack(spacing: 8) {
            Text("age_label")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(store.age))
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var categoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TemplateCategory.allCases) { cat in
                    categoryButton(for: cat)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func categoryButton(for cat: TemplateCategory) -> some View {
        Button {
            store.selectedCategory = cat
        } label: {
            HStack(spacing: 6) {
                Text(cat.icon)
                Text(cat.localizedTitleKey)
                    .font(.subheadline)
                    .fontWeight(store.selectedCategory == cat ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(categoryBackground(isSelected: store.selectedCategory == cat))
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func categoryBackground(isSelected: Bool) -> LinearGradient {
        let colors = isSelected ? [Color.pink.opacity(0.6), Color.orange.opacity(0.6)] : [Color.secondary.opacity(0.12), Color.secondary.opacity(0.06)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var templatesSection: some View {
        let templates = store.filteredTemplates()
        return Section {
            ForEach(templates) { template in
                templateRow(template)
            }

            if templates.isEmpty {
                Text("no_templates_message")
                    .foregroundStyle(.secondary)
            }

            if templates.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                generateFromSearchButton
            }
        } header: {
            Text("templates_title")
        }
    }

    private func templateRow(_ template: DrawingTemplate) -> some View {
        NavigationLink {
            DrawView(template: template)
        } label: {
            HStack(spacing: 12) {
                SVGTemplatePreview(svg: template.svgPath, rasterPNGData: template.rasterPNGData)
                    .frame(width: 56, height: 56)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    Text("Ages \(template.ageMin)–\(template.ageMax) · \(template.category.capitalized)")
                    Text("Ages \((template.ageMin))–\((template.ageMax)) · \((template.category.capitalized))")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var generateFromSearchButton: some View {
        Button {
            Task { await generateFromSearch() }
        } label: {
            HStack {
                if isGenerating { ProgressView().padding(.trailing, 6) }
                if isGenerating {
                    Text("generating_label")
                } else {
                    Text(verbatim: "Generate a new template from ‘\(searchText)’")
                }
            }
        }
        .disabled(isGenerating)
    }

    private var addTemplateToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingCreateTemplate = true
            } label: {
                Label("create_template_button", systemImage: "plus.circle")
            }
        }
    }

    private var createTemplateSheet: some View {
        NavigationStack {
            Form {
                describeTemplateSection
                previewSection
            }
            .navigationTitle("create_template_title")
            .toolbar { createTemplateToolbar }
            .onChange(of: createPrompt) { _ in Task { await refreshAISVG() } }
            .onChange(of: useAppleIntelligence) { _ in Task { await refreshAISVG() } }
        }
    }

    private var describeTemplateSection: some View {
        Section("describe_template_section") {
            if #available(iOS 18.0, *) {
                Toggle("use_ai_toggle", isOn: $useAppleIntelligence)
            } else {
                EmptyView()
            }
            TextField("create_placeholder", text: $createPrompt)
        }
    }

    private var previewSection: some View {
        Section("preview_section") {
            if useAppleIntelligence, let svg = aiSVG {
                SVGTemplatePreview(svg: svg)
                    .frame(height: 180)
            } else if let svg = generateSVG(from: createPrompt) {
                SVGTemplatePreview(svg: svg)
                    .frame(height: 180)
            } else {
                Text("preview_hint")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var createTemplateToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel_button") { showingCreateTemplate = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("add_button") { addTemplateFromPrompt() }
                    .disabled((useAppleIntelligence ? (aiSVG ?? "").isEmpty : (generateSVG(from: createPrompt) ?? "").isEmpty))
            }
        }
    }

    private func addTemplateFromPrompt() {
        let svg = (useAppleIntelligence ? (aiSVG ?? "") : (generateSVG(from: createPrompt) ?? ""))
        guard !svg.isEmpty else { return }
        let name = createPrompt.isEmpty ? String(localized: "custom_template_name") : createPrompt.capitalized
        let new = DrawingTemplate(
            id: UUID().uuidString,
            name: name,
            svgPath: svg,
            ageMin: max(3, min(store.age, 12)),
            ageMax: max(3, min(store.age, 12)),
            category: store.selectedCategory == .all ? TemplateCategory.shapes.rawValue : store.selectedCategory.rawValue
        )
        store.addTemplate(new)
        showingCreateTemplate = false
        createPrompt = ""
    }

    private func handleSearchSubmit() {
        applySearchQuery(searchText)
        Task { await applySearchQueryAI(searchText) }
        Task {
            if store.filteredTemplates().isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await generateFromSearch()
            }
        }
    }

    private func updateAgeFromActiveProfile() {
        if let active = activeProfileStore.activeProfile {
            store.age = active.age
        } else if let first = profiles.first {
            store.age = first.age
        }
    }
    
    private func applySearchQuery(_ text: String) {
        let lc = text.lowercased()
        // Extract age number if present
        if let num = lc.split(whereSeparator: { !$0.isNumber }).compactMap({ Int($0) }).first {
            store.age = min(12, max(3, num))
        }
        // Match category by rawValue
        for c in TemplateCategory.allCases where c != .all {
            if lc.contains(c.rawValue) { store.selectedCategory = c; break }
        }
    }
    
    @MainActor private func applySearchQueryAI(_ text: String) async {
        let service: QueryUnderstandingService = AIBackedQueryUnderstandingService()
        if let intent = await service.parse(text: text) {
            if let age = intent.age { store.age = min(12, max(3, age)) }
            if let cat = intent.category { store.selectedCategory = cat }
            // keywords are available via intent.keywords if needed
        }
    }

    @MainActor private func refreshAISVG() async {
        guard useAppleIntelligence else { aiSVG = nil; return }
        let planner = AITemplatePlanner()
        do {
            let plan = try await planner.plan(from: createPrompt, bounds: CGSize(width: 400, height: 400))
            aiSVG = svg(from: plan)
        } catch {
            aiSVG = nil
        }
    }

    private func generateSVG(from prompt: String) -> String? {
        let lc = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lc.isEmpty else { return nil }
        // Very simple rules-based generator producing a 400x400-friendly outline
        if lc.contains("sun") {
            // circle + rays
            return """
            <circle cx="200" cy="200" r="80" stroke-width="6"/>
            <line x1="200" y1="40" x2="200" y2="80" stroke-width="6"/>
            <line x1="200" y1="320" x2="200" y2="360" stroke-width="6"/>
            <line x1="40" y1="200" x2="80" y2="200" stroke-width="6"/>
            <line x1="320" y1="200" x2="360" y2="200" stroke-width="6"/>
            <line x1="90" y1="90" x2="120" y2="120" stroke-width="6"/>
            <line x1="280" y1="280" x2="310" y2="310" stroke-width="6"/>
            <line x1="280" y1="120" x2="310" y2="90" stroke-width="6"/>
            <line x1="90" y1="310" x2="120" y2="280" stroke-width="6"/>
            """
        } else if lc.contains("house") || lc.contains("home") {
            // rectangle + roof triangle + door
            return """
            <rect x="100" y="160" width="200" height="160" stroke-width="6"/>
            <polygon points="100,160 200,80 300,160" stroke-width="6"/>
            <rect x="180" y="240" width="40" height="80" stroke-width="6"/>
            """
        } else if lc.contains("rocket") {
            // body + fins + window
            return """
            <polygon points="200,60 240,160 240,300 160,300 160,160" stroke-width="6"/>
            <polygon points="160,260 120,320 160,320" stroke-width="6"/>
            <polygon points="240,260 280,320 240,320" stroke-width="6"/>
            <circle cx="200" cy="200" r="20" stroke-width="6"/>
            """
        } else if lc.contains("cat") {
            // head + ears + eyes + whiskers
            return """
            <circle cx="200" cy="200" r="80" stroke-width="6"/>
            <polygon points="150,140 180,120 170,160" stroke-width="6"/>
            <polygon points="250,140 220,120 230,160" stroke-width="6"/>
            <circle cx="175" cy="200" r="8" stroke-width="6"/>
            <circle cx="225" cy="200" r="8" stroke-width="6"/>
            <line x1="160" y1="220" x2="120" y2="230" stroke-width="4"/>
            <line x1="160" y1="230" x2="120" y2="240" stroke-width="4"/>
            <line x1="240" y1="220" x2="280" y2="230" stroke-width="4"/>
            <line x1="240" y1="230" x2="280" y2="240" stroke-width="4"/>
            """
        } else if lc.contains("flower") {
            return """
            <circle cx="200" cy="200" r="30" stroke-width="6"/>
            <circle cx="200" cy="130" r="40" stroke-width="6"/>
            <circle cx="270" cy="200" r="40" stroke-width="6"/>
            <circle cx="200" cy="270" r="40" stroke-width="6"/>
            <circle cx="130" cy="200" r="40" stroke-width="6"/>
            <line x1="200" y1="270" x2="200" y2="360" stroke-width="6"/>
            """
        } else if lc.contains("car") || lc.contains("vehicle") || lc.contains("truck") {
            return """
            <rect x="80" y="220" width="240" height="80" rx="20" ry="20" stroke-width="6"/>
            <rect x="160" y="170" width="80" height="50" rx="14" ry="14" stroke-width="6"/>
            <circle cx="140" cy="320" r="28" stroke-width="6"/>
            <circle cx="260" cy="320" r="28" stroke-width="6"/>
            """
        }
        // Default simple shape
        return """
        <rect x="80" y="120" width="240" height="160" rx="12" ry="12" stroke-width="6"/>
        """
    }

    @MainActor private func generateFromSearch() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // Understand the query
        let intent = await queryService.parse(text: text) ?? TemplateQueryIntent()
        let prompt = intent.generationPrompt

        // Try AI image generation first
        let targetSize = CGSize(width: 1024, height: 1024)
        var png: Data?
        do {
            png = try await imageGenerator.generateImage(for: prompt, size: targetSize)
        } catch {
            png = nil
        }

        // If AI failed or not available, use parametric renderer for vehicles
        if png == nil {
            let strokeWidth = max(4, min(targetSize.width, targetSize.height) * 0.02)
            png = templateRenderer.renderTemplate(category: intent.category, keywords: intent.keywords, size: targetSize, strokeWidth: strokeWidth)
        }

        guard let data = png, !data.isEmpty else { return }

        // Convert PNG to a simple SVG wrapper path (outline) placeholder, or store raster? Here we embed as a raster-backed template by converting to a basic SVG image tag sized for 400x400 canvas.
        // For immediate integration with existing SVG-based UI, we create a simple bounding-rect outline as SVG and rely on the raster for preview elsewhere. Alternatively, if your pipeline requires SVG paths only, we can store a placeholder shape.
        let svgFallback = """
        <rect x=\"40\" y=\"40\" width=\"320\" height=\"320\" rx=\"16\" ry=\"16\" stroke-width=\"6\"/>
        """

        let name = text.capitalized
        let category = (intent.category ?? store.selectedCategory).rawValue
        let ageMin = intent.age ?? store.age
        let new = DrawingTemplate(
            id: UUID().uuidString,
            name: name,
            svgPath: svgFallback,
            ageMin: max(3, min(ageMin, 12)),
            ageMax: max(3, min(ageMin, 12)),
            category: category,
            rasterPNGData: data
        )
        store.addTemplate(new)

        // Optionally, present a full-screen preview of the generated raster
        if let ui = UIImage(data: data) {
            // Show a quick preview sheet using FullScreenImagePreview
            // You may choose to store this PNG in your persistence for later use.
            // For now, we just show it to the user.
            let preview = FullScreenImagePreview(image: ui, isPresented: .constant(true))
            // Present using a temporary window scene if needed; in SwiftUI, require a binding. For simplicity, we skip presenting automatically.
            // Consider wiring a dedicated preview state if you want automatic presentation.
        }
    }
}

// MARK: - Composite renderer that delegates by category
final class CompositeTemplateRenderer: TemplateRenderer {
    private let car = ParametricCarTemplateRenderer()
    private let animal = ParametricAnimalTemplateRenderer()
    private let nature = ParametricNatureTemplateRenderer()
    private let building = ParametricBuildingTemplateRenderer()
    func renderTemplate(category: TemplateCategory?, keywords: [String], size: CGSize, strokeWidth: CGFloat) -> Data {
        switch category {
        case .some(.vehicles):
            return car.renderTemplate(category: category, keywords: keywords, size: size, strokeWidth: strokeWidth)
        case .some(.animals):
            return animal.renderTemplate(category: category, keywords: keywords, size: size, strokeWidth: strokeWidth)
        case .some(.nature):
            return nature.renderTemplate(category: category, keywords: keywords, size: size, strokeWidth: strokeWidth)
        case .some(.buildings):
            return building.renderTemplate(category: category, keywords: keywords, size: size, strokeWidth: strokeWidth)
        default:
            // Heuristic: check keywords
            let lowered = keywords.joined(separator: " ").lowercased()
            if lowered.contains("car") || lowered.contains("truck") { return car.renderTemplate(category: .vehicles, keywords: keywords, size: size, strokeWidth: strokeWidth) }
            if lowered.contains("cat") || lowered.contains("dog") || lowered.contains("animal") { return animal.renderTemplate(category: .animals, keywords: keywords, size: size, strokeWidth: strokeWidth) }
            if lowered.contains("tree") || lowered.contains("flower") || lowered.contains("nature") { return nature.renderTemplate(category: .nature, keywords: keywords, size: size, strokeWidth: strokeWidth) }
            if lowered.contains("house") || lowered.contains("home") || lowered.contains("building") || lowered.contains("skyscraper") { return building.renderTemplate(category: .buildings, keywords: keywords, size: size, strokeWidth: strokeWidth) }
            // Default to nature for a pleasant outline
            return nature.renderTemplate(category: .nature, keywords: keywords, size: size, strokeWidth: strokeWidth)
        }
    }
}

extension TemplateCategory {
    var localizedTitleKey: String {
        switch self {
        case .all: return "category_all"
        case .animals: return "category_animals"
        case .vehicles: return "category_vehicles"
        case .shapes: return "category_shapes"
        case .nature: return "category_nature"
        case .buildings: return "category_buildings"
        case .fantasy: return "category_fantasy"
        }
    }
}

