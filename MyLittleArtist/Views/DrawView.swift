import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension View {
    func onSizeChange(_ action: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}

private func templateFillPath(for template: DrawingTemplate) -> Path {
    SVGTemplateParser.fillPath(svg: template.svgPath)
}

struct DrawView: View {
    let template: DrawingTemplate
    @Environment(\.modelContext) private var modelContext

    @State private var strokes: [DrawStroke] = []
    @State private var undoStack: [[DrawStroke]] = [] // NEW: Undo history
    @State private var current: DrawStroke?
    @State private var selectedColor: Color = .black
    @State private var lineWidth: CGFloat = 8
    @State private var isErasing: Bool = false
    @State private var showGrid: Bool = false
    @State private var showBrushPreview: Bool = true // NEW: Brush size preview
    @State private var showSavedAlert: Bool = false

    @State private var canvasSize: CGSize = .zero
    @State private var showClearConfirmation: Bool = false // NEW: Clear confirmation

    @AppStorage("profileName") private var profileName: String = ""
    @AppStorage("userName") private var userName_fallback: String = ""
    @AppStorage("name") private var name_fallback: String = ""

    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    private var selectedLocale: Locale { Locale(identifier: appLanguage) }

    private var displayProfileName: String {
        [profileName, userName_fallback, name_fallback]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    // NEW: Can undo check
    private var canUndo: Bool {
        !undoStack.isEmpty
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.97, blue: 0.90),
                    Color(red: 0.92, green: 0.96, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Profile name display
                if !displayProfileName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        Text(displayProfileName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Main controls with undo/redo
                HStack(spacing: 12) {
                    // NEW: Undo button
                    Button {
                        performUndo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!canUndo)
                    .buttonStyle(.bordered)
                    
                    Slider(value: $lineWidth, in: 2...30) {
                        Text(String(localized: "brush_label"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: 160)
                    .fixedSize(horizontal: false, vertical: true)

                    // NEW: Brush size preview
                    if showBrushPreview {
                        Circle()
                            .fill(isErasing ? Color.white : selectedColor)
                            .frame(width: lineWidth, height: lineWidth)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .frame(width: 44, height: 44)
                    }

                    Toggle(isOn: $isErasing) {
                        Image(systemName: isErasing ? "eraser.fill" : "pencil.tip")
                            .font(.title3)
                    }
                    .toggleStyle(.button)
                    .frame(width: 44, height: 44)
                    .help("Toggle eraser")

                    Button {
                        showGrid.toggle()
                    } label: {
                        Image(systemName: showGrid ? "square.grid.3x3.fill" : "square.grid.3x3")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                    .help(String(localized: "grid_label"))
                }
                .padding(.horizontal)

                // Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.06))

                    // Template outline
                    SVGTemplateCanvas(svg: template.svgPath)
                        .allowsHitTesting(false)

                    // User drawing
                    DrawingCanvas(
                        strokes: $strokes,
                        current: $current,
                        strokeColor: selectedColor,
                        lineWidth: lineWidth,
                        isErasing: isErasing,
                        showGrid: showGrid,
                        maskPathTemplateSpace: templateFillPath(for: template),
                        enableMasking: !showGrid,
                        onStrokeCompleted: { saveToUndoStack() } // NEW: Save undo state
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(16)
                }
                .padding(.horizontal)
                .onSizeChange { canvasSize = $0 }

                // Action buttons
                HStack(spacing: 12) {
                    // NEW: Clear with confirmation
                    Button(role: .destructive) {
                        if strokes.isEmpty {
                            return
                        }
                        showClearConfirmation = true
                    } label: {
                        Label(String(localized: "clear_button"), systemImage: "trash")
                    }
                    .disabled(strokes.isEmpty)
                    .confirmationDialog(
                        String(localized: "confirm_clear_message"),
                        isPresented: $showClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "confirm_clear_confirm"), role: .destructive) {
                            saveToUndoStack()
                            strokes.removeAll()
                        }
                        Button(String(localized: "confirm_clear_cancel"), role: .cancel) {}
                    }

                    Spacer()
                    
                    Button {
                        saveDrawing()
                    } label: {
                        Label(String(localized: "save_button"), systemImage: "square.and.arrow.down")
                    }
                    .disabled(strokes.isEmpty)
                }
                .padding(.horizontal)

                // NEW: Color palette view (replacing basic ColorPicker)
                ColorPaletteView(selectedColor: $selectedColor)
                    .padding(.top, 4)

            }
        }
        .navigationTitle(Text(template.localizedNameKey))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, selectedLocale)
        .alert("Saved to Gallery", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your drawing has been saved to the Gallery.")
        }
    }
    
    // MARK: - NEW: Undo/Redo Functions
    
    private func saveToUndoStack() {
        // Avoid pushing duplicate consecutive states
        if let last = undoStack.last, last == strokes { return }
        undoStack.append(strokes)
        if undoStack.count > 20 { undoStack.removeFirst() }
    }
    
    private func performUndo() {
        guard !undoStack.isEmpty else { return }
        // Remove current state snapshot
        let _ = undoStack.removeLast()
        // Restore previous snapshot if available, else clear
        if let previous = undoStack.last {
            strokes = previous
        } else {
            strokes.removeAll()
        }
    }
    
    // MARK: - Drawing Capture & Save
    
    private func captureDrawing() -> UIImage? {
        let targetSize: CGSize = canvasSize == .zero ? CGSize(width: UIScreen.main.bounds.width - 32, height: UIScreen.main.bounds.width * 1.2) : canvasSize

        let content = ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
            SVGTemplateCanvas(svg: template.svgPath)
                .allowsHitTesting(false)
            DrawingCanvas(
                strokes: .constant(strokes),
                current: .constant(current),
                strokeColor: selectedColor,
                lineWidth: lineWidth,
                isErasing: false,
                showGrid: false,
                maskPathTemplateSpace: templateFillPath(for: template),
                enableMasking: false
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(16)
        }
        .frame(width: targetSize.width, height: targetSize.height)

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale

        guard let cgImage = renderer.cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
    
    private func saveDrawing() {
        guard let uiImage = captureDrawing(),
              let png = uiImage.pngData(),
              !png.isEmpty else {
            assertionFailure("Save failed: Could not capture drawing")
            return
        }

        let saved = SavedDrawing(
            templateId: template.id,
            templateName: template.name,
            imageData: png
        )
        modelContext.insert(saved)
        try? modelContext.save()
        showSavedAlert = true
    }
}

