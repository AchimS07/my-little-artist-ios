import SwiftUI
import SwiftData

@main
struct MyLittleArtistApp: App {
    
    @StateObject private var activeProfileStore = ActiveProfileStore()
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    private var selectedLocale: Locale { Locale(identifier: appLanguage) }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingGateView()
            }
            .environmentObject(activeProfileStore)
            .environment(\.locale, selectedLocale)
            .overlay(LaunchOverlay())
        }
        .modelContainer(for: [UserProfile.self, SavedDrawing.self])
    }
}
private struct LaunchOverlay: View {
    @State private var show = true

    var body: some View {
        ZStack {
            if show {
                LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.4), Color(red: 0.6, green: 0.85, blue: 1.0)], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 72))
                        .symbolRenderingMode(.multicolor)
                        .shadow(radius: 4)
                    Text("launch_title")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundStyle(.primary)
                    Text("launch_subtitle")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(32)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(radius: 12)
                .padding()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeInOut(duration: 0.6)) { show = false }
        }
        .accessibilityHidden(!show)
    }
}

