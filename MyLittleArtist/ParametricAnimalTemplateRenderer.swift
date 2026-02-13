import UIKit

final class ParametricAnimalTemplateRenderer: TemplateRenderer {
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
            if lowered.contains("cat") || lowered.contains("kitten") {
                drawCat(in: rect, context: cg)
            } else if lowered.contains("dog") || lowered.contains("puppy") {
                drawDog(in: rect, context: cg)
            } else if lowered.contains("bunny") || lowered.contains("rabbit") {
                drawBunny(in: rect, context: cg)
            } else if lowered.contains("elephant") {
                drawElephant(in: rect, context: cg)
            } else {
                drawGenericAnimal(in: rect, context: cg)
            }
        }
        return img.pngData() ?? Data()
    }

    private func drawCat(in rect: CGRect, context cg: CGContext) {
        let headR = min(rect.width, rect.height) * 0.28
        let headC = CGPoint(x: rect.midX, y: rect.midY)
        let head = UIBezierPath(ovalIn: CGRect(x: headC.x - headR, y: headC.y - headR, width: headR*2, height: headR*2))
        cg.addPath(head.cgPath); cg.strokePath()
        // ears
        let earH = headR * 0.9
        let leftEar = UIBezierPath()
        leftEar.move(to: CGPoint(x: headC.x - headR*0.6, y: headC.y - headR*0.2))
        leftEar.addLine(to: CGPoint(x: headC.x - headR*0.2, y: headC.y - earH))
        leftEar.addLine(to: CGPoint(x: headC.x - headR*0.05, y: headC.y - headR*0.1))
        leftEar.close()
        cg.addPath(leftEar.cgPath); cg.strokePath()
        let rightEar = UIBezierPath()
        rightEar.move(to: CGPoint(x: headC.x + headR*0.6, y: headC.y - headR*0.2))
        rightEar.addLine(to: CGPoint(x: headC.x + headR*0.2, y: headC.y - earH))
        rightEar.addLine(to: CGPoint(x: headC.x + headR*0.05, y: headC.y - headR*0.1))
        rightEar.close()
        cg.addPath(rightEar.cgPath); cg.strokePath()
        // eyes
        let eyeR: CGFloat = headR * 0.08
        let eyeY = headC.y - headR * 0.05
        drawEye(center: CGPoint(x: headC.x - headR*0.3, y: eyeY), r: eyeR, context: cg)
        drawEye(center: CGPoint(x: headC.x + headR*0.3, y: eyeY), r: eyeR, context: cg)
        // whiskers
        let y1 = headC.y + headR*0.1
        for i in 0..<2 {
            let dy = CGFloat(i) * headR*0.08
            cg.move(to: CGPoint(x: headC.x - headR*0.1, y: y1 + dy))
            cg.addLine(to: CGPoint(x: headC.x - headR*0.8, y: y1 + dy))
            cg.move(to: CGPoint(x: headC.x + headR*0.1, y: y1 + dy))
            cg.addLine(to: CGPoint(x: headC.x + headR*0.8, y: y1 + dy))
        }
        cg.strokePath()
    }

    private func drawDog(in rect: CGRect, context cg: CGContext) {
        let headR = min(rect.width, rect.height) * 0.28
        let headC = CGPoint(x: rect.midX, y: rect.midY)
        let head = UIBezierPath(ovalIn: CGRect(x: headC.x - headR, y: headC.y - headR, width: headR*2, height: headR*2))
        cg.addPath(head.cgPath); cg.strokePath()
        // floppy ears
        let earW = headR * 0.5
        let earH = headR * 0.7
        let leftEar = UIBezierPath(roundedRect: CGRect(x: headC.x - headR - earW*0.2, y: headC.y - earH*0.5, width: earW, height: earH), cornerRadius: earW*0.5)
        cg.addPath(leftEar.cgPath); cg.strokePath()
        let rightEar = UIBezierPath(roundedRect: CGRect(x: headC.x + headR - earW*0.8, y: headC.y - earH*0.5, width: earW, height: earH), cornerRadius: earW*0.5)
        cg.addPath(rightEar.cgPath); cg.strokePath()
        // eyes
        let eyeR: CGFloat = headR * 0.08
        let eyeY = headC.y - headR * 0.05
        drawEye(center: CGPoint(x: headC.x - headR*0.3, y: eyeY), r: eyeR, context: cg)
        drawEye(center: CGPoint(x: headC.x + headR*0.3, y: eyeY), r: eyeR, context: cg)
        // nose
        let nose = UIBezierPath(ovalIn: CGRect(x: headC.x - headR*0.08, y: headC.y + headR*0.1, width: headR*0.16, height: headR*0.12))
        cg.addPath(nose.cgPath); cg.strokePath()
    }

    private func drawGenericAnimal(in rect: CGRect, context cg: CGContext) {
        let headR = min(rect.width, rect.height) * 0.3
        let headC = CGPoint(x: rect.midX, y: rect.midY)
        let head = UIBezierPath(roundedRect: CGRect(x: headC.x - headR, y: headC.y - headR, width: headR*2, height: headR*2), cornerRadius: headR*0.3)
        cg.addPath(head.cgPath); cg.strokePath()
        drawEye(center: CGPoint(x: headC.x - headR*0.3, y: headC.y), r: headR*0.08, context: cg)
        drawEye(center: CGPoint(x: headC.x + headR*0.3, y: headC.y), r: headR*0.08, context: cg)
    }

    private func drawEye(center: CGPoint, r: CGFloat, context cg: CGContext) {
        let p = UIBezierPath(ovalIn: CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
        cg.addPath(p.cgPath); cg.strokePath()
    }

    private func drawBunny(in rect: CGRect, context cg: CGContext) {
        let headR = min(rect.width, rect.height) * 0.26
        let headC = CGPoint(x: rect.midX, y: rect.midY + headR*0.1)
        let head = UIBezierPath(ovalIn: CGRect(x: headC.x - headR, y: headC.y - headR, width: headR*2, height: headR*2))
        cg.addPath(head.cgPath); cg.strokePath()
        // ears
        let earW = headR * 0.5
        let earH = headR * 1.2
        let leftEar = UIBezierPath(roundedRect: CGRect(x: headC.x - earW*1.1, y: headC.y - headR*1.7, width: earW, height: earH), cornerRadius: earW*0.5)
        let rightEar = UIBezierPath(roundedRect: CGRect(x: headC.x + earW*0.1, y: headC.y - headR*1.7, width: earW, height: earH), cornerRadius: earW*0.5)
        cg.addPath(leftEar.cgPath); cg.strokePath()
        cg.addPath(rightEar.cgPath); cg.strokePath()
        // eyes
        let eyeR = headR * 0.08
        drawEye(center: CGPoint(x: headC.x - headR*0.28, y: headC.y), r: eyeR, context: cg)
        drawEye(center: CGPoint(x: headC.x + headR*0.28, y: headC.y), r: eyeR, context: cg)
    }

    private func drawElephant(in rect: CGRect, context cg: CGContext) {
        let headR = min(rect.width, rect.height) * 0.26
        let headC = CGPoint(x: rect.midX, y: rect.midY)
        let head = UIBezierPath(roundedRect: CGRect(x: headC.x - headR, y: headC.y - headR*0.8, width: headR*2, height: headR*1.6), cornerRadius: headR*0.4)
        cg.addPath(head.cgPath); cg.strokePath()
        // trunk
        let trunk = UIBezierPath()
        trunk.move(to: CGPoint(x: headC.x, y: headC.y + headR*0.6))
        trunk.addCurve(to: CGPoint(x: headC.x, y: headC.y + headR*1.3), controlPoint1: CGPoint(x: headC.x + headR*0.4, y: headC.y + headR*1.0), controlPoint2: CGPoint(x: headC.x - headR*0.4, y: headC.y + headR*1.1))
        cg.addPath(trunk.cgPath); cg.strokePath()
        // ears
        let earR = headR * 0.9
        let leftEar = UIBezierPath(ovalIn: CGRect(x: headC.x - headR - earR*0.9, y: headC.y - earR*0.6, width: earR, height: earR))
        let rightEar = UIBezierPath(ovalIn: CGRect(x: headC.x + headR - earR*0.1, y: headC.y - earR*0.6, width: earR, height: earR))
        cg.addPath(leftEar.cgPath); cg.strokePath()
        cg.addPath(rightEar.cgPath); cg.strokePath()
    }
}
