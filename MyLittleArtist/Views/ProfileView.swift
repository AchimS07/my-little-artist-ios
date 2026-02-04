import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

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
            if profile == nil {
                if let existing = profiles.first {
                    profile = existing
                } else {
                    let new = UserProfile(id: UUID(), name: "", age: 6)
                    modelContext.insert(new)
                    profile = new
                }
            }
        }
    }
}

