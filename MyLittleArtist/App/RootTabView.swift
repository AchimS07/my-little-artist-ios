import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TemplatesView()
            }
            .tabItem { Label(String(localized: "tab_templates"), systemImage: "square.grid.2x2") }

            NavigationStack {
                GalleryView()
            }
            .tabItem { Label(String(localized: "tab_gallery"), systemImage: "photo.on.rectangle") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label(String(localized: "tab_profile"), systemImage: "person.crop.circle") }
        }
    }
}
