import UIKit

final class ParametricBuildingTemplateRenderer: TemplateRenderer {
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
            if lowered.contains("castle") || lowered.contains("fort") {
                drawCastle(in: rect, context: cg)
            } else if lowered.contains("skyscraper") || lowered.contains("tower") {
                drawSkyscraper(in: rect, context: cg)
            } else {
                drawHouse(in: rect, context: cg)
            }
        }
        return img.pngData() ?? Data()
    }

    private func drawHouse(in rect: CGRect, context cg: CGContext) {
        let body = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.28, y: rect.midY, width: rect.width*0.56, height: rect.height*0.32), cornerRadius: rect.width*0.04)
        cg.addPath(body.cgPath); cg.strokePath()
        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: rect.midX - rect.width*0.3, y: rect.midY))
        roof.addLine(to: CGPoint(x: rect.midX, y: rect.midY - rect.height*0.22))
        roof.addLine(to: CGPoint(x: rect.midX + rect.width*0.3, y: rect.midY))
        cg.addPath(roof.cgPath); cg.strokePath()
        let door = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.06, y: rect.midY + rect.height*0.16, width: rect.width*0.12, height: rect.height*0.16), cornerRadius: rect.width*0.02)
        cg.addPath(door.cgPath); cg.strokePath()
        // windows
        let winSize = CGSize(width: rect.width*0.12, height: rect.height*0.1)
        let leftWin = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.22, y: rect.midY + rect.height*0.06, width: winSize.width, height: winSize.height), cornerRadius: rect.width*0.02)
        let rightWin = UIBezierPath(roundedRect: CGRect(x: rect.midX + rect.width*0.1, y: rect.midY + rect.height*0.06, width: winSize.width, height: winSize.height), cornerRadius: rect.width*0.02)
        cg.addPath(leftWin.cgPath); cg.strokePath()
        cg.addPath(rightWin.cgPath); cg.strokePath()
    }

    private func drawSkyscraper(in rect: CGRect, context cg: CGContext) {
        let body = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.18, y: rect.minY + rect.height*0.18, width: rect.width*0.36, height: rect.height*0.64), cornerRadius: rect.width*0.04)
        cg.addPath(body.cgPath); cg.strokePath()
        // windows grid
        let cols = 3
        let rows = 6
        let spacingX = (rect.width*0.28) / CGFloat(cols + 1)
        let spacingY = (rect.height*0.5) / CGFloat(rows + 1)
        for r in 1...rows {
            for c in 1...cols {
                let x = rect.midX - rect.width*0.14 + CGFloat(c) * spacingX
                let y = rect.minY + rect.height*0.24 + CGFloat(r) * spacingY
                let win = UIBezierPath(roundedRect: CGRect(x: x - rect.width*0.035, y: y - rect.height*0.025, width: rect.width*0.07, height: rect.height*0.05), cornerRadius: rect.width*0.01)
                cg.addPath(win.cgPath); cg.strokePath()
            }
        }
    }

    private func drawCastle(in rect: CGRect, context cg: CGContext) {
        let base = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.32, y: rect.midY + rect.height*0.05, width: rect.width*0.64, height: rect.height*0.28), cornerRadius: rect.width*0.02)
        cg.addPath(base.cgPath); cg.strokePath()
        // central tower
        let tower = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.12, y: rect.midY - rect.height*0.12, width: rect.width*0.24, height: rect.height*0.36), cornerRadius: rect.width*0.02)
        cg.addPath(tower.cgPath); cg.strokePath()
        // battlements
        let battlementCount = 5
        let bw = (rect.width*0.24) / CGFloat(battlementCount)
        for i in 0..<battlementCount {
            let x = rect.midX - rect.width*0.12 + CGFloat(i) * bw
            let b = UIBezierPath(rect: CGRect(x: x + bw*0.1, y: rect.midY - rect.height*0.12 - bw*0.4, width: bw*0.8, height: bw*0.4))
            cg.addPath(b.cgPath); cg.strokePath()
        }
        // door
        let door = UIBezierPath(roundedRect: CGRect(x: rect.midX - rect.width*0.06, y: rect.midY + rect.height*0.18, width: rect.width*0.12, height: rect.height*0.15), cornerRadius: rect.width*0.02)
        cg.addPath(door.cgPath); cg.strokePath()
    }
}
