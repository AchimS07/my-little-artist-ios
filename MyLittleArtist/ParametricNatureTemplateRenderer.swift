import UIKit

final class ParametricNatureTemplateRenderer: TemplateRenderer {
    func renderTemplate(category: TemplateCategory?, keywords: [String], size: CGSize, strokeWidth: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setStrokeColor(UIColor.label.cgColor)
            cg.setLineWidth(strokeWidth)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)

            let inset: CGFloat = max(strokeWidth * 1.5, 8)
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let lowered = keywords.joined(separator: " ").lowercased()
            if lowered.contains("flower") || lowered.contains("blossom") {
                drawFlower(in: rect, context: cg)
            } else if lowered.contains("mountain") || lowered.contains("mountains") {
                drawMountain(in: rect, context: cg)
            } else if lowered.contains("cloud") || lowered.contains("clouds") {
                drawCloud(in: rect, context: cg)
            } else {
                drawTree(in: rect, context: cg)
            }
        }
        return img.pngData() ?? Data()
    }

    private func drawTree(in rect: CGRect, context cg: CGContext) {
        let crown = UIBezierPath(ovalIn: CGRect(x: rect.midX - rect.width*0.25, y: rect.minY + rect.height*0.15, width: rect.width*0.5, height: rect.height*0.45))
        cg.addPath(crown.cgPath); cg.strokePath()
        let trunk = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.05, y: rect.midY, width: rect.width*0.1, height: rect.height*0.3), cornerRadius: rect.width*0.05)
        cg.addPath(trunk.cgPath); cg.strokePath()
        // small branch hints
        cg.move(to: CGPoint(x: rect.midX, y: rect.midY + rect.height*0.1))
        cg.addLine(to: CGPoint(x: rect.midX + rect.width*0.15, y: rect.midY + rect.height*0.05))
        cg.move(to: CGPoint(x: rect.midX, y: rect.midY + rect.height*0.18))
        cg.addLine(to: CGPoint(x: rect.midX - rect.width*0.15, y: rect.midY + rect.height*0.12))
        cg.strokePath()
    }

    private func drawFlower(in rect: CGRect, context cg: CGContext) {
        let centerR = min(rect.width, rect.height) * 0.06
        let center = UIBezierPath(ovalIn: CGRect(x: rect.midX - centerR, y: rect.midY - centerR, width: centerR*2, height: centerR*2))
        cg.addPath(center.cgPath); cg.strokePath()
        let petalR = centerR * 2.2
        for i in 0..<6 {
            let angle = CGFloat(i) * (.pi * 2 / 6)
            let cx = rect.midX + cos(angle) * petalR * 1.2
            let cy = rect.midY + sin(angle) * petalR * 1.2
            let petal = UIBezierPath(ovalIn: CGRect(x: cx - petalR, y: cy - petalR, width: petalR*2, height: petalR*2))
            cg.addPath(petal.cgPath); cg.strokePath()
        }
        // stem
        cg.move(to: CGPoint(x: rect.midX, y: rect.midY + petalR*1.2))
        cg.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.1))
        cg.strokePath()
    }

    private func drawMountain(in rect: CGRect, context cg: CGContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width*0.1, y: rect.maxY - rect.height*0.1))
        path.addLine(to: CGPoint(x: rect.midX - rect.width*0.05, y: rect.minY + rect.height*0.35))
        path.addLine(to: CGPoint(x: rect.midX + rect.width*0.1, y: rect.maxY - rect.height*0.1))
        cg.addPath(path.cgPath); cg.strokePath()
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: rect.midX + rect.width*0.1, y: rect.maxY - rect.height*0.1))
        path2.addLine(to: CGPoint(x: rect.maxX - rect.width*0.1, y: rect.minY + rect.height*0.45))
        path2.addLine(to: CGPoint(x: rect.maxX - rect.width*0.05, y: rect.maxY - rect.height*0.1))
        cg.addPath(path2.cgPath); cg.strokePath()
    }

    private func drawCloud(in rect: CGRect, context cg: CGContext) {
        let r = min(rect.width, rect.height) * 0.12
        let centers = [
            CGPoint(x: rect.midX - r*1.8, y: rect.midY),
            CGPoint(x: rect.midX - r*0.6, y: rect.midY - r*0.6),
            CGPoint(x: rect.midX + r*0.8, y: rect.midY),
            CGPoint(x: rect.midX + r*2.0, y: rect.midY - r*0.4)
        ]
        for c in centers {
            let p = UIBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r*2, height: r*2))
            cg.addPath(p.cgPath); cg.strokePath()
        }
    }
}
