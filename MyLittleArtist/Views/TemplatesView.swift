import SwiftUI
import SwiftData

struct TemplatesView: View {
    @StateObject private var store = TemplatesStore()
    @Environment(\.modelContext) private var modelContext
    @Query var profiles: [UserProfile]
    
    private var activeAge: Binding<Int> {
        if let profile = profiles.first {
            return Binding(
                get: { profile.age },
                set: { new in profile.age = new; store.age = new }
            )
        } else {
            return $store.age
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.8), Color(red: 0.9, green: 0.95, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            List {
                Section {
                    HStack(spacing: 12) {
                        Text("Age")
                            .font(.headline)
                        Spacer()
                        Stepper(value: activeAge, in: 3...12) {
                            Text("\(activeAge.wrappedValue)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TemplateCategory.allCases) { cat in
                                Button {
                                    store.selectedCategory = cat
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(cat.icon)
                                        Text(cat.title)
                                            .font(.subheadline)
                                            .fontWeight(store.selectedCategory == cat ? .semibold : .regular)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(colors: store.selectedCategory == cat ? [Color.pink.opacity(0.6), Color.orange.opacity(0.6)] : [Color.secondary.opacity(0.12), Color.secondary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Templates") {
                    ForEach(store.filteredTemplates()) { template in
                        NavigationLink {
                            DrawView(template: template)
                        } label: {
                            HStack(spacing: 12) {
                                SVGTemplatePreview(svg: template.svgPath)
                                    .frame(width: 56, height: 56)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text("Ages \(template.ageMin)–\(template.ageMax) · \(template.category.capitalized)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    if store.filteredTemplates().isEmpty {
                        Text("No templates for this age/category.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("My Little Artist")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
    }
}
