import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    @State private var profile: UserProfile?
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    private let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.9, green: 1.0, blue: 0.95)],
        startPoint: .top,
        endPoint: .bottom
    )

    private let avatarGridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var nameBinding: Binding<String> {
        Binding(
            get: { profile?.name ?? "" },
            set: { newValue in profile?.name = newValue }
        )
    }

    private var ageBinding: Binding<Int> {
        Binding(
            get: { profile?.age ?? 6 },
            set: { newValue in profile?.age = newValue }
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            Group {
                if profile != nil {
                    Form {
                        Section("profile_kid_section") {
                            TextField("profile_name_placeholder", text: nameBinding)
                            Stepper(value: ageBinding, in: 3...12) {
                                Text("profile_age_label", tableName: nil, bundle: nil, comment: "Profile age label") + Text(" \(ageBinding.wrappedValue)")
                            }
                        }
                        Section("profile_avatar_section") {
                            let avatars = ["🦁","🐰","🦊","🐼","🦄","🐶","🐱","🦋","🐸","🐻"]
                            LazyVGrid(columns: avatarGridColumns, spacing: 8) {
                                ForEach(avatars, id: \.self) { emo in
                                    Button {
                                        self.profile?.avatarEmoji = emo
                                    } label: {
                                        Text(emo)
                                            .font(.system(size: 28))
                                            .frame(maxWidth: .infinity)
                                            .padding(6)
                                            .background(((self.profile?.avatarEmoji == emo) ? Color.purple.opacity(0.25) : Color.secondary.opacity(0.08)))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        Section("profile_language_section") {
                            Picker("profile_language_picker", selection: $appLanguage) {
                                Text("language.english").tag("en")
                                Text("language.romanian").tag("ro")
                            }
                            .pickerStyle(.segmented)
                        }
                        Section("profile_about_section") {
                            Text("profile_about_text")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("profile_title")
        .task {
            // Prefer the active profile if available
            if let active = activeProfileStore.activeProfile {
                profile = active
                return
            }

            // Attempt to load from existing profiles (e.g., on cold start)
            if profile == nil {
                if let existing = profiles.first(where: { $0.id == activeProfileStore.activeProfileID }) {
                    profile = existing
                    return
                }
                if let first = profiles.first {
                    profile = first
                    return
                }

                // No profiles exist yet: create one and make it active
                let new = UserProfile(id: UUID(), name: "", age: 6)
                modelContext.insert(new)
                profile = new
                activeProfileStore.select(new)
            }
        }
    }
}

