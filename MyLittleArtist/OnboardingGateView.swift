import SwiftUI
import SwiftData

struct OnboardingGateView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showingCreate = false
    @State private var goToApp = false
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    @AppStorage("lastSelectedProfileID") private var lastSelectedProfileID: String = ""

    var body: some View {
        ZStack {
            // ✅ Full screen background owned by this screen
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.85),
                    Color(red: 0.9, green: 0.95, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                if profiles.isEmpty || showingCreate {
                    CreateProfileView { new in
                        modelContext.insert(new)
                        try? modelContext.save()

                        lastSelectedProfileID = new.id.uuidString
                        showingCreate = false

                        // ✅ Proper navigation trigger
                        activeProfileStore.select(new)
                        goToApp = true
                    } onBack: {
                        showingCreate = false
                    }
                } else {
                    ProfilesHubView(profiles: profiles) { picked in
                        lastSelectedProfileID = picked.id.uuidString

                        // ✅ Proper navigation trigger
                        activeProfileStore.select(picked)
                        goToApp = true
                    } onAdd: {
                        showingCreate = true
                    }
                }
            }
            .padding()
        }
        // ✅ Proper, state-driven navigation (no .constant)
        .navigationDestination(isPresented: $goToApp) {
            RootTabView()
        }
        
        .onAppear {
            activeProfileStore.load(from: profiles)
        }
        .onChange(of: profiles) { _, newProfiles in
            activeProfileStore.load(from: newProfiles)
        }

    }
}
