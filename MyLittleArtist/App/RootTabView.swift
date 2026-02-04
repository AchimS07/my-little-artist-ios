import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TemplatesView()
            }
            .tabItem { Label("Templates", systemImage: "square.grid.2x2") }

            NavigationStack {
                GalleryView()
            }
            .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
