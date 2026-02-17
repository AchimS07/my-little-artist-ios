import SwiftUI
import SwiftData

struct TemplatesView: View {
    @StateObject private var store = TemplatesStore()
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    @State private var searchText: String = ""

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
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("search_prompt")
        )
        .onSubmit(of: .search) { handleSearchSubmit() }
    }

    private var backgroundGradient: LinearGradient {
        let backgroundColors: [Color] = [
            Color(red: 1.0, green: 0.95, blue: 0.8),
            Color(red: 0.9, green: 0.95, blue: 1.0)
        ]
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
                .font(.subheadline.weight(.semibold))
            Spacer()
            Stepper("", value: $store.age, in: 3...12)
                .labelsHidden()
        }
    }

    private var categoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TemplateCategory.allCases) { cat in
                    Button {
                        store.selectedCategory = cat
                    } label: {
                        HStack(spacing: 8) {
                            Text(cat.icon)
                            Text(LocalizedStringKey(cat.localizedTitleKey))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(categoryBackground(isSelected: store.selectedCategory == cat))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryBackground(isSelected: Bool) -> LinearGradient {
        let colors = isSelected
        ? [Color.pink.opacity(0.6), Color.orange.opacity(0.6)]
        : [Color.secondary.opacity(0.12), Color.secondary.opacity(0.06)]
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
        } header: {
            Text("templates_title")
        }
    }

    private func templateRow(_ template: DrawingTemplate) -> some View {
        NavigationLink {
            DrawView(template: template)
        } label: {
            HStack(spacing: 12) {
                Image(template.templateAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.localizedNameKey)
                    Group {
                        Text(LocalizedStringKey("template_age_range_format"))
                        Text(" \(template.ageMin)–\(template.ageMax) · ")
                        Text(LocalizedStringKey("template_category_prefix"))
                        Text(LocalizedStringKey(template.category))
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func handleSearchSubmit() {
        applySearchQuery(searchText)
        Task { await applySearchQueryAI(searchText) }
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
        if let num = lc.split(whereSeparator: { !$0.isNumber }).compactMap({ Int($0) }).first {
            store.age = min(12, max(3, num))
        }
        for c in TemplateCategory.allCases where c != .all {
            if lc.contains(c.rawValue) { store.selectedCategory = c; break }
        }
    }

    @MainActor private func applySearchQueryAI(_ text: String) async {
        let service: QueryUnderstandingService = AIBackedQueryUnderstandingService()
        if let intent = await service.parse(text: text) {
            if let age = intent.age { store.age = min(12, max(3, age)) }
            if let cat = intent.category { store.selectedCategory = cat }
        }
    }
}

extension TemplateCategory {
    var localizedTitleKey: String {
        switch self {
        case .all: return "All"
        case .animals: return "Animals"
        case .vehicles: return "Vehicles"
        case .shapes: return "Shapes"
        case .nature: return "Nature"
        case .buildings: return "Buildings"
        case .food: return "Food"
        case .fantasy: return "Fantasy"
        @unknown default: return "Unknown"
        }
    }
}
