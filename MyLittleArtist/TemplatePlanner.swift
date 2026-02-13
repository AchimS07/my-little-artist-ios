import Foundation
import CoreGraphics

struct TemplatePlan: Codable {
    struct Element: Codable {
        enum Kind: String, Codable { case circle, rect, line, polygon, ellipse }
        var type: Kind
        var strokeWidth: Double
        var cx: Double?
        var cy: Double?
        var r: Double?
        var x: Double?
        var y: Double?
        var width: Double?
        var height: Double?
        var x1: Double?
        var y1: Double?
        var x2: Double?
        var y2: Double?
        var points: [[Double]]?
    }
    var name: String
    var elements: [Element]
}

protocol TemplatePlanner {
    func plan(from prompt: String, bounds: CGSize) async throws -> TemplatePlan
}

enum TemplatePlannerError: Error { case emptyPrompt, notAvailable, badResponse, tooComplex }

final class AITemplatePlanner: TemplatePlanner {
    private let client: AIModelClient = StubAIModelClient()
    
    func plan(from prompt: String, bounds: CGSize) async throws -> TemplatePlan {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TemplatePlannerError.emptyPrompt }
        guard #available(iOS 18.0, *) else { throw TemplatePlannerError.notAvailable }

        do {
            // Attempt AI model call via client (stubbed for now)
            guard let json = try await client.generatePlanJSON(system: systemPrompt(bounds: bounds), prompt: trimmed) else {
                throw TemplatePlannerError.notAvailable
            }
            let data = Data(json.utf8)
            var plan = try JSONDecoder().decode(TemplatePlan.self, from: data)
            validateAndClamp(&plan, bounds: bounds)
            return plan
        } catch {
            throw error
        }
    }

    private func systemPrompt(bounds: CGSize) -> String {
        """
        You are a planner that outputs a JSON plan for drawing templates in a \(Int(bounds.width))x\(Int(bounds.height)) space.
        Use only these element types: circle, rect, line, polygon, ellipse. Each element includes strokeWidth.
        Output strictly JSON matching:
        {
          "name": String,
          "elements": [
            { "type": "circle" | "rect" | "line" | "polygon" | "ellipse",
              "strokeWidth": Number,
              "cx": Number, "cy": Number, "r": Number,
              "x": Number, "y": Number, "width": Number, "height": Number,
              "x1": Number, "y1": Number, "x2": Number, "y2": Number,
              "points": [[Number, Number], ...]
            }
          ]
        }
        Constraints:
        - Coordinates within [0,\(Int(bounds.width))] and [0,\(Int(bounds.height))]
        - strokeWidth in [1,12]
        - Max 30 elements
        """
    }
}

protocol AIModelClient {
    func generatePlanJSON(system: String, prompt: String) async throws -> String?
}

struct StubAIModelClient: AIModelClient {
    func generatePlanJSON(system: String, prompt: String) async throws -> String? {
        // Return nil to force fallback until a real model is wired in
        return nil
    }
}

func svg(from plan: TemplatePlan) -> String {
    var out: [String] = []
    for el in plan.elements {
        let sw = Int(el.strokeWidth.rounded())
        switch el.type {
        case .circle:
            let cx = Int((el.cx ?? 200).rounded())
            let cy = Int((el.cy ?? 200).rounded())
            let r  = Int((el.r  ?? 40 ).rounded())
            out.append("<circle cx=\"\(cx)\" cy=\"\(cy)\" r=\"\(r)\" stroke-width=\"\(sw)\"/>")
        case .rect:
            let x = Int((el.x ?? 100).rounded())
            let y = Int((el.y ?? 100).rounded())
            let w = Int((el.width  ?? 200).rounded())
            let h = Int((el.height ?? 160).rounded())
            out.append("<rect x=\"\(x)\" y=\"\(y)\" width=\"\(w)\" height=\"\(h)\" stroke-width=\"\(sw)\"/>")
        case .line:
            let x1 = Int((el.x1 ?? 100).rounded())
            let y1 = Int((el.y1 ?? 100).rounded())
            let x2 = Int((el.x2 ?? 300).rounded())
            let y2 = Int((el.y2 ?? 300).rounded())
            out.append("<line x1=\"\(x1)\" y1=\"\(y1)\" x2=\"\(x2)\" y2=\"\(y2)\" stroke-width=\"\(sw)\"/>")
        case .polygon:
            let pts = (el.points ?? []).map { "\($0[0]),\($0[1])" }.joined(separator: " ")
            out.append("<polygon points=\"\(pts)\" stroke-width=\"\(sw)\"/>")
        case .ellipse:
            let cx = Int((el.cx ?? 200).rounded())
            let cy = Int((el.cy ?? 200).rounded())
            let rx = Int((el.width  ?? 60 ).rounded())
            let ry = Int((el.height ?? 40 ).rounded())
            out.append("<ellipse cx=\"\(cx)\" cy=\"\(cy)\" rx=\"\(rx)\" ry=\"\(ry)\" stroke-width=\"\(sw)\"/>")
        }
    }
    return out.joined(separator: "\n")
}
func validateAndClamp(_ plan: inout TemplatePlan, bounds: CGSize, maxElements: Int = 30) {
    let maxW = Double(bounds.width)
    let maxH = Double(bounds.height)
    func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(hi, max(lo, v)) }

    if plan.elements.count > maxElements {
        plan.elements = Array(plan.elements.prefix(maxElements))
    }
    for i in plan.elements.indices {
        plan.elements[i].strokeWidth = clamp(plan.elements[i].strokeWidth, 1, 12)
        if let cx = plan.elements[i].cx { plan.elements[i].cx = clamp(cx, 0, maxW) }
        if let cy = plan.elements[i].cy { plan.elements[i].cy = clamp(cy, 0, maxH) }
        if let r  = plan.elements[i].r  { plan.elements[i].r  = clamp(r, 0, min(maxW, maxH)) }
        if let x  = plan.elements[i].x  { plan.elements[i].x  = clamp(x, 0, maxW) }
        if let y  = plan.elements[i].y  { plan.elements[i].y  = clamp(y, 0, maxH) }
        if let w  = plan.elements[i].width  { plan.elements[i].width  = clamp(w, 0, maxW) }
        if let h  = plan.elements[i].height { plan.elements[i].height = clamp(h, 0, maxH) }
        if let x1 = plan.elements[i].x1 { plan.elements[i].x1 = clamp(x1, 0, maxW) }
        if let y1 = plan.elements[i].y1 { plan.elements[i].y1 = clamp(y1, 0, maxH) }
        if let x2 = plan.elements[i].x2 { plan.elements[i].x2 = clamp(x2, 0, maxW) }
        if let y2 = plan.elements[i].y2 { plan.elements[i].y2 = clamp(y2, 0, maxH) }
        if var pts = plan.elements[i].points {
            for j in pts.indices {
                if pts[j].count >= 2 {
                    pts[j][0] = clamp(pts[j][0], 0, maxW)
                    pts[j][1] = clamp(pts[j][1], 0, maxH)
                }
            }
            plan.elements[i].points = pts
        }
    }
}

