import SwiftUI
import SwiftData

private struct SelectedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct GalleryView: View {
    @Query(sort: \SavedDrawing.date, order: .reverse) private var drawings: [SavedDrawing]
    
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var selectedFullScreen: SelectedImage? = nil

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
                            ZStack(alignment: .topTrailing) {
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

                                Button {
                                    if let dataImage = (item.uiImage ?? item.thumbnail) {
                                        shareItems = [dataImage]
                                        showShareSheet = true
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(6)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .padding(6)
                            }
                            .onTapGesture {
                                if let ui = (item.uiImage ?? item.thumbnail) {
                                    selectedFullScreen = SelectedImage(image: ui)
                                }
                            }
                            .contextMenu {
                                Button {
                                    if let dataImage = (item.uiImage ?? item.thumbnail) {
                                        shareItems = [dataImage]
                                        showShareSheet = true
                                    }
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gallery")
        .sheet(isPresented: $showShareSheet) {
            if shareItems.isEmpty {
                VStack { Text("Nothing to share") }
            } else {
                ActivityView(activityItems: shareItems)
            }
        }
        .fullScreenCover(item: $selectedFullScreen) { wrapper in
            FullScreenImageViewer(image: wrapper.image)
        }
    }
}
