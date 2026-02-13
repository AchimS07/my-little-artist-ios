import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    @State private var profile: UserProfile?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.9, green: 1.0, blue: 0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Group {
                if let profile = profile {
                    Form {
                        Section("Kid Profile") {
                            TextField("Name", text: Binding(
                                get: { profile.name },
                                set: { profile.name = $0 }
                            ))
                            Stepper(value: Binding(
                                get: { profile.age },
                                set: { profile.age = $0 }
                            ), in: 3...12) {
                                Text("Age: \(profile.age)")
                            }
                        }
                        Section("Avatar") {
                            let avatars = ["🦁","🐰","🦊","🐼","🦄","🐶","🐱","🦋","🐸","🐻"]
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                ForEach(avatars, id: \.self) { emo in
                                    Button {
                                        profile.avatarEmoji = emo
                                    } label: {
                                        Text(emo)
                                            .font(.system(size: 28))
                                            .frame(maxWidth: .infinity)
                                            .padding(6)
                                            .background((profile.avatarEmoji == emo ? Color.purple.opacity(0.25) : Color.secondary.opacity(0.08)))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Section("About") {
                            Text("Customize your profile and your age will be used to filter templates on the home screen.")
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
        .navigationTitle("Profile")
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

