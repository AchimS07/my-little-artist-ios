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
    @State private var snapshotImage: UIImage?

    @State private var selectedColor: Color = .black
    @State private var lineWidth: CGFloat = 8
    @State private var isErasing: Bool = false
    @State private var showGrid: Bool = false
    @State private var showBrushPreview: Bool = true // NEW: Brush size preview
    
    @State private var canvasSize: CGSize = .zero
    @State private var kidName: String = ""
    @State private var showClearConfirmation: Bool = false // NEW: Clear confirmation
    @State private var showShareSheet: Bool = false // NEW: Share functionality
    
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
                    }
                    .frame(maxWidth: 180)

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
                    }
                    .toggleStyle(.button)
                    .help("Toggle eraser")

                    Toggle(String(localized: "grid_label"), isOn: $showGrid)
                        .toggleStyle(.switch)
                    
                    TextField(String(localized: "child_name_placeholder"), text: $kidName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .submitLabel(.done)
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
                    
                    // Profile name overlay
                    HStack {
                        if !displayProfileName.isEmpty {
                            Text(displayProfileName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding([.top, .leading], 20)
                        }
                        Spacer()
                    }
                    .padding(16)
                    
                    // Kid name overlay
                    VStack {
                        Spacer()
                        if !kidName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(kidName)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.bottom, 20)
                        }
                    }
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
                    
                    // NEW: Share button
                    Button {
                        if let image = captureDrawing() {
                            showShareSheet = true
                        }
                    } label: {
                        Label(String(localized: "share_button", defaultValue: "Share"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(strokes.isEmpty)

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

                Text(String(localized: "tip_text"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, selectedLocale)
        .sheet(isPresented: $showShareSheet) {
            if let image = captureDrawing() {
                ActivityView(activityItems: [image])
            }
        }
    }
    
    // MARK: - NEW: Undo/Redo Functions
    
    private func saveToUndoStack() {
        undoStack.append(strokes)
        // Limit undo history to last 20 states
        if undoStack.count > 20 {
            undoStack.removeFirst()
        }
    }
    
    private func performUndo() {
        guard !undoStack.isEmpty else { return }
        strokes = undoStack.removeLast()
    }
    
    // MARK: - Drawing Capture & Save
    
    private func captureDrawing() -> UIImage? {
        guard canvasSize != .zero else { return nil }

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
            
            HStack {
                if !displayProfileName.isEmpty {
                    Text(displayProfileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding([.top, .leading], 20)
                }
                Spacer()
            }
            .padding(16)
            
            VStack {
                Spacer()
                if !kidName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(kidName)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 20)
                }
            }
            .padding(16)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)

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
    }
}

