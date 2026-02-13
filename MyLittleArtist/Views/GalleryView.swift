import SwiftUI
import SwiftData

struct GalleryView: View {
    @Query(sort: \SavedDrawing.date, order: .reverse) private var drawings: [SavedDrawing]

    var body: some View {
        Group {
            if drawings.isEmpty {
                ContentUnavailableView(
                    "Gallery",
                    systemImage: "photo.on.rectangle",
                    description: Text("Your saved drawings will appear here.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(drawings, id: \.id) { item in
                            VStack(spacing: 8) {
                                if let ui = item.thumbnail ?? item.uiImage {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.1))
                                        .overlay(Image(systemName: "photo").font(.largeTitle))
                                        .frame(height: 120)
                                }
                                Text(item.templateName)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gallery")
    }
}
