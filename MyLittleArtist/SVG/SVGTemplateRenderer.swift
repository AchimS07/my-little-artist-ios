import SwiftUI
import Foundation
import UIKit

// MARK: - Public Views

struct SVGTemplatePreview: View {
    let svg: String
    var rasterPNGData: Data? = nil

    var body: some View {
        if let data = rasterPNGData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .padding(10)
        } else {
            SVGTemplateCanvas(svg: svg)
                .padding(10)
        }
    }
}

struct SVGTemplateCanvas: View {
    let svg: String

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let elements = SVGTemplateParser.parse(svg: svg)
            Canvas { context, canvasSize in
                let scale = min(canvasSize.width, canvasSize.height) / 400.0
                var transform = CGAffineTransform.identity
                transform = transform
                    .translatedBy(x: (canvasSize.width - 400*scale)/2, y: (canvasSize.height - 400*scale)/2)
                    .scaledBy(x: scale, y: scale)

                for el in elements {
                    var path = el.path
                    path = path.applying(transform)
                    context.stroke(
                        path,
                        with: .color(.primary.opacity(0.9)),
                        style: StrokeStyle(lineWidth: max(1, el.strokeWidth * scale), lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Parser

enum SVGTemplateParser {
    struct Element {
        var path: Path
        var strokeWidth: CGFloat
    }

    static func parse(svg: String) -> [Element] {
        // svg is a concatenation of basic tags: circle, rect, ellipse, line, polygon, path
        var result: [Element] = []
        let tagRegex = try! NSRegularExpression(pattern: #"<(circle|rect|ellipse|line|polygon|path)\b[^>]*/?>"#, options: [])
        let ns = svg as NSString
        for m in tagRegex.matches(in: svg, options: [], range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: m.range)
            let strokeWidth = CGFloat(parseNumber(attr(tag, "stroke-width")) ?? 3.0)

            if tag.contains("<circle") {
                if let cx = parseNumber(attr(tag, "cx")),
                   let cy = parseNumber(attr(tag, "cy")),
                   let r  = parseNumber(attr(tag, "r")) {
                    let rect = CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r)
                    result.append(.init(path: Path(ellipseIn: rect), strokeWidth: strokeWidth))
                }
            } else if tag.contains("<ellipse") {
                if let cx = parseNumber(attr(tag, "cx")),
                   let cy = parseNumber(attr(tag, "cy")),
                   let rx = parseNumber(attr(tag, "rx")),
                   let ry = parseNumber(attr(tag, "ry")) {
                    let rect = CGRect(x: cx - rx, y: cy - ry, width: 2*rx, height: 2*ry)
                    result.append(.init(path: Path(ellipseIn: rect), strokeWidth: strokeWidth))
                }
            } else if tag.contains("<rect") {
                if let x = parseNumber(attr(tag, "x")),
                   let y = parseNumber(attr(tag, "y")),
                   let w = parseNumber(attr(tag, "width")),
                   let h = parseNumber(attr(tag, "height")) {
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    result.append(.init(path: Path(rect), strokeWidth: strokeWidth))
                }
            } else if tag.contains("<line") {
                if let x1 = parseNumber(attr(tag, "x1")),
                   let y1 = parseNumber(attr(tag, "y1")),
                   let x2 = parseNumber(attr(tag, "x2")),
                   let y2 = parseNumber(attr(tag, "y2")) {
                    var p = Path()
                    p.move(to: CGPoint(x: x1, y: y1))
                    p.addLine(to: CGPoint(x: x2, y: y2))
                    result.append(.init(path: p, strokeWidth: strokeWidth))
                }
            } else if tag.contains("<polygon") {
                if let pointsStr = attr(tag, "points") {
                    let pts = parsePoints(pointsStr)
                    if let first = pts.first {
                        var p = Path()
                        p.move(to: first)
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                        p.closeSubpath()
                        result.append(.init(path: p, strokeWidth: strokeWidth))
                    }
                }
            } else if tag.contains("<path") {
                if let d = attr(tag, "d") {
                    let p = SVGPathParser.parsePath(d)
                    result.append(.init(path: p, strokeWidth: strokeWidth))
                }
            }
        }
        return result
    }

    static func fillPath(svg: String) -> Path {
        var combined = Path()
        let tagRegex = try! NSRegularExpression(pattern: #"<(circle|rect|ellipse|line|polygon|path)\b[^>]*/?>"#, options: [])
        let ns = svg as NSString
        for m in tagRegex.matches(in: svg, options: [], range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: m.range)
            if tag.contains("<circle") {
                if let cx = parseNumber(attr(tag, "cx")),
                   let cy = parseNumber(attr(tag, "cy")),
                   let r  = parseNumber(attr(tag, "r")) {
                    let rect = CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r)
                    combined.addPath(Path(ellipseIn: rect))
                }
            } else if tag.contains("<ellipse") {
                if let cx = parseNumber(attr(tag, "cx")),
                   let cy = parseNumber(attr(tag, "cy")),
                   let rx = parseNumber(attr(tag, "rx")),
                   let ry = parseNumber(attr(tag, "ry")) {
                    let rect = CGRect(x: cx - rx, y: cy - ry, width: 2*rx, height: 2*ry)
                    combined.addPath(Path(ellipseIn: rect))
                }
            } else if tag.contains("<rect") {
                if let x = parseNumber(attr(tag, "x")),
                   let y = parseNumber(attr(tag, "y")),
                   let w = parseNumber(attr(tag, "width")),
                   let h = parseNumber(attr(tag, "height")) {
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    combined.addPath(Path(rect))
                }
            } else if tag.contains("<polygon") {
                if let pointsStr = attr(tag, "points") {
                    let pts = parsePoints(pointsStr)
                    if let first = pts.first {
                        var p = Path()
                        p.move(to: first)
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                        p.closeSubpath()
                        combined.addPath(p)
                    }
                }
            } else if tag.contains("<path") {
                if let d = attr(tag, "d") {
                    let p = SVGPathParser.parsePath(d)
                    combined.addPath(p)
                }
            } else {
                // lines have no interior — ignore
            }
        }
        return combined
    }

    private static func attr(_ tag: String, _ name: String) -> String? {
        let pattern = name + #"=\"([^\"]+)\""#
        let r = try! NSRegularExpression(pattern: pattern, options: [])
        let ns = tag as NSString
        guard let m = r.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: ns.length)) else { return nil }
        return ns.substring(with: m.range(at: 1))
    }

    private static func parseNumber(_ s: String?) -> Double? {
        guard let s else { return nil }
        return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func parsePoints(_ s: String) -> [CGPoint] {
        // "x,y x,y x,y"
        let parts = s
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
        var pts: [CGPoint] = []
        for p in parts {
            let xy = p.split(separator: ",")
            if xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]) {
                pts.append(CGPoint(x: x, y: y))
            }
        }
        return pts
    }
}

// MARK: - SVG Path (M, L, C, Q, Z)

enum SVGPathParser {
    static func parsePath(_ d: String) -> Path {
        var tokens = tokenize(d)
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero

        func readPoint() -> CGPoint? {
            guard let x = tokens.popDouble(), let y = tokens.popDouble() else { return nil }
            return CGPoint(x: x, y: y)
        }

        while let cmd = tokens.popCommand() {
            switch cmd {
            case "M":
                if let p = readPoint() {
                    path.move(to: p)
                    current = p
                    start = p
                    // Some SVG allow multiple pairs after M as implicit L
                    while tokens.peekIsNumber, let p2 = readPoint() {
                        path.addLine(to: p2)
                        current = p2
                    }
                }
            case "L":
                while tokens.peekIsNumber, let p = readPoint() {
                    path.addLine(to: p)
                    current = p
                }
            case "C":
                while tokens.peekIsNumber {
                    guard let c1 = readPoint(),
                          let c2 = readPoint(),
                          let p  = readPoint() else { break }
                    path.addCurve(to: p, control1: c1, control2: c2)
                    current = p
                }
            case "Q":
                while tokens.peekIsNumber {
                    guard let c = readPoint(),
                          let p = readPoint() else { break }
                    path.addQuadCurve(to: p, control: c)
                    current = p
                }
            case "Z":
                path.closeSubpath()
                current = start
            default:
                // Unsupported command – ignore gracefully
                break
            }
        }

        return path
    }

    private struct TokenStream {
        var items: [String]
        var idx: Int = 0

        var peek: String? { idx < items.count ? items[idx] : nil }
        var peekIsNumber: Bool {
            guard let p = peek else { return false }
            return Double(p) != nil
        }

        mutating func popCommand() -> String? {
            // Skip separators/empties
            while let p = peek, p.isEmpty { idx += 1 }
            guard let p = peek else { return nil }
            if p.count == 1, let ch = p.first, ch.isLetter {
                idx += 1
                return p
            }
            // Some paths omit repeating command letters; we can’t infer safely, so stop.
            return nil
        }

        mutating func popDouble() -> Double? {
            while let p = peek, p.isEmpty { idx += 1 }
            guard let p = peek, let v = Double(p) else { return nil }
            idx += 1
            return v
        }
    }

    private static func tokenize(_ d: String) -> TokenStream {
        // Split by commands and numbers. Supports commas and spaces.
        var out: [String] = []
        var cur = ""
        func flush() {
            if !cur.isEmpty { out.append(cur); cur = "" }
        }
        for ch in d {
            if ch.isLetter {
                flush()
                out.append(String(ch))
            } else if ch == "-" {
                flush()
                cur.append(ch)
            } else if ch.isNumber || ch == "." {
                cur.append(ch)
            } else if ch == "," || ch == " " || ch == "\n" || ch == "\t" {
                flush()
            } else {
                // ignore
                flush()
            }
        }
        flush()
        return TokenStream(items: out)
    }
}

