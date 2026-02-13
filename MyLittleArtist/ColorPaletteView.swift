import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ColorPaletteView: View {
    @Binding var selectedColor: Color

    @State private var recentColors: [Color] = [
        .black, .red, .orange, .yellow, .green, .blue, .purple, .brown, .white
    ]
    @State private var showPicker = false
    @AppStorage("recentColorsHex") private var recentHex: String = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(recentColors.indices, id: \.self) { i in
                    let color = recentColors[i]
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(selectedColor.isSame(as: color) ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        .onTapGesture { selectedColor = color }
                        .accessibilityLabel("Color swatch \(i + 1)")
                }

                Button {
                    showPicker.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Add color")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .sheet(isPresented: $showPicker) {
            VStack(spacing: 16) {
                Text("Pick a color")
                    .font(.headline)
                ColorPicker("", selection: $selectedColor, supportsOpacity: true)
                    .labelsHidden()
                    .padding()
                Button("Add to palette") {
                    if !recentColors.contains(where: { $0.isSame(as: selectedColor) }) {
                        recentColors.insert(selectedColor, at: 0)
                        if recentColors.count > 16 { recentColors.removeLast() }
                    }
                    showPicker = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            if !recentHex.isEmpty {
                let decoded = recentHex.split(separator: ",").compactMap { Color(hex: String($0)) }
                if !decoded.isEmpty { recentColors = decoded }
            }
        }
        .onChange(of: recentColors) { colors in
            recentHex = colors.map { $0.toHexString() }.joined(separator: ",")
        }
    }
}

// MARK: - Color helpers

private extension Color {
    func toHexString() -> String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "000000FF" }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255)), ai = Int(round(a * 255))
        return String(format: "%02X%02X%02X%02X", ri, gi, bi, ai)
        #else
        return "000000FF"
        #endif
    }

    init?(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard let val = UInt64(hex, radix: 16) else { return nil }
        let r, g, b, a: Double
        if hex.count == 8 {
            r = Double((val >> 24) & 0xFF) / 255.0
            g = Double((val >> 16) & 0xFF) / 255.0
            b = Double((val >> 8) & 0xFF) / 255.0
            a = Double(val & 0xFF) / 255.0
        } else if hex.count == 6 {
            r = Double((val >> 16) & 0xFF) / 255.0
            g = Double((val >> 8) & 0xFF) / 255.0
            b = Double(val & 0xFF) / 255.0
            a = 1.0
        } else {
            return nil
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }

    func isSame(as other: Color) -> Bool {
        #if canImport(UIKit)
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        guard a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa), b.getRed(&br, green: &bg, blue: &bb, alpha: &ba) else { return false }
        return abs(ar-br) < 0.01 && abs(ag-bg) < 0.01 && abs(ab-bb) < 0.01 && abs(aa-ba) < 0.01
        #else
        return false
        #endif
    }
}

#Preview {
    StatefulPreviewWrapper(Color.blue) { binding in
        ColorPaletteView(selectedColor: binding)
            .padding()
            .background(Color.secondary.opacity(0.08))
    }
}

// Helper to preview bindings
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }
    var body: some View { content($value) }
}

