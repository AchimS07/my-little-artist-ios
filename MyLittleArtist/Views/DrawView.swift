import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

private func templateFillPath(for template: DrawingTemplate) -> Path {
    SVGTemplateParser.fillPath(svg: template.svgPath)
}

struct DrawView: View {
    let template: DrawingTemplate
    @Environment(\.modelContext) private var modelContext

    @State private var strokes: [DrawStroke] = []
    @State private var current: DrawStroke?
    @State private var snapshotImage: UIImage?

    @State private var selectedColor: Color = .black
    @State private var lineWidth: CGFloat = 8
    @State private var isErasing: Bool = false
    @State private var showGrid: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Controls
            HStack(spacing: 12) {
                Slider(value: $lineWidth, in: 2...30) {
                    Text("Brush")
                }
                .frame(maxWidth: 220)

                Toggle(isOn: $isErasing) {
                    Image(systemName: isErasing ? "eraser.fill" : "pencil.tip")
                }
                .toggleStyle(.button)
                .help("Toggle eraser")

                Toggle("Grid", isOn: $showGrid)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.06))

                // Template outline
                SVGTemplateCanvas(svg: template.svgPath)
                    .allowsHitTesting(false)
                    .padding(16)

                // User drawing
                DrawingCanvas(
                    strokes: $strokes,
                    current: $current,
                    strokeColor: selectedColor,
                    lineWidth: lineWidth,
                    isErasing: isErasing,
                    showGrid: showGrid,
                    maskPathTemplateSpace: templateFillPath(for: template),
                    enableMasking: !showGrid
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(2)
            }
            .padding(.horizontal)

            HStack {
                Button(role: .destructive) {
                    strokes.removeAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                }

                Spacer()

                Button {
                    let size = CGSize(width: 800, height: 800)
                    let content = ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                        SVGTemplateCanvas(svg: template.svgPath)
                            .padding(16)
                        DrawingCanvas(
                            strokes: .constant(strokes),
                            current: .constant(nil),
                            strokeColor: selectedColor,
                            lineWidth: lineWidth,
                            isErasing: isErasing,
                            showGrid: showGrid
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(2)
                    }
                    .frame(width: size.width, height: size.height)

                    let renderer = ImageRenderer(content: content)
                    renderer.scale = UIScreen.main.scale
                    if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
                        let saved = SavedDrawing(templateId: template.id, templateName: template.name, imageData: data)
                        modelContext.insert(saved)
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(strokes.isEmpty)
            }
            .padding(.horizontal)

            ColorPicker("", selection: $selectedColor, supportsOpacity: true)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 4)

            Text("Tip: draw with your finger (or trackpad in Simulator).")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

