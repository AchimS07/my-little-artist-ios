import UIKit

final class ParametricCarTemplateRenderer: TemplateRenderer {
    func renderTemplate(category: TemplateCategory?, keywords: [String], size: CGSize = CGSize(width: 256, height: 128), strokeWidth: CGFloat = 4) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setStrokeColor(UIColor.label.cgColor)
            cg.setLineWidth(strokeWidth)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)

            // Inset drawing rect
            let inset: CGFloat = max(strokeWidth * 1.5, 8)
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)

            // Decide if this is a car-like request
            let isCar = (category == .vehicles) || keywords.contains(where: { $0.localizedCaseInsensitiveContains("car") || $0.localizedCaseInsensitiveContains("truck") })

            if isCar {
                drawCar(in: rect, context: cg)
            } else {
                // Fallback: simple rounded rectangle frame
                let path = UIBezierPath(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.06)
                cg.addPath(path.cgPath)
                cg.strokePath()
            }
        }
        return img.pngData() ?? Data()
    }

    private func drawCar(in rect: CGRect, context cg: CGContext) {
        // Proportions
        let wheelRadius = min(rect.width, rect.height) * 0.09
        let wheelY = rect.maxY - wheelRadius
        let wheelSpacing = rect.width * 0.28
        let centerX = rect.midX

        // Wheels
        let leftWheelCenter = CGPoint(x: centerX - wheelSpacing/2, y: wheelY)
        let rightWheelCenter = CGPoint(x: centerX + wheelSpacing/2, y: wheelY)
        drawWheel(center: leftWheelCenter, radius: wheelRadius, context: cg)
        drawWheel(center: rightWheelCenter, radius: wheelRadius, context: cg)

        // Body
        let bodyHeight = rect.height * 0.28
        let bodyTop = wheelY - wheelRadius - bodyHeight
        let bodyRect = CGRect(x: rect.minX + wheelRadius * 0.8,
                              y: bodyTop,
                              width: rect.width - wheelRadius * 1.6,
                              height: bodyHeight)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: bodyHeight * 0.35)
        cg.addPath(bodyPath.cgPath)
        cg.strokePath()

        // Cabin (slightly inset, rounded top)
        let cabinWidth = bodyRect.width * 0.44
        let cabinHeight = bodyRect.height * 0.9
        let cabinRect = CGRect(x: bodyRect.midX - cabinWidth * 0.1,
                               y: bodyRect.minY - cabinHeight * 0.88,
                               width: cabinWidth,
                               height: cabinHeight)
        let cabinPath = UIBezierPath(roundedRect: cabinRect, cornerRadius: cabinHeight * 0.4)
        cg.addPath(cabinPath.cgPath)
        cg.strokePath()

        // Bumper hints
        let bumperInset = bodyRect.height * 0.25
        let frontBumper = CGRect(x: bodyRect.maxX - bumperInset * 0.5, y: bodyRect.minY + bumperInset, width: bumperInset * 0.4, height: bodyRect.height - bumperInset * 2)
        cg.addPath(UIBezierPath(roundedRect: frontBumper, cornerRadius: bumperInset * 0.2).cgPath)
        cg.strokePath()
        let rearBumper = CGRect(x: bodyRect.minX - bumperInset * 0.9, y: bodyRect.minY + bumperInset, width: bumperInset * 0.7, height: bodyRect.height - bumperInset * 2)
        cg.addPath(UIBezierPath(roundedRect: rearBumper, cornerRadius: bumperInset * 0.2).cgPath)
        cg.strokePath()

        // Window split line
        let splitY = cabinRect.midY
        cg.move(to: CGPoint(x: cabinRect.minX + cabinRect.width * 0.08, y: splitY))
        cg.addLine(to: CGPoint(x: cabinRect.maxX - cabinRect.width * 0.08, y: splitY))
        cg.strokePath()
    }

    private func drawWheel(center: CGPoint, radius: CGFloat, context cg: CGContext) {
        let outer = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        cg.addPath(outer.cgPath)
        cg.strokePath()

        // Inner circle hint
        let innerR = radius * 0.45
        let inner = UIBezierPath(ovalIn: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2))
        cg.addPath(inner.cgPath)
        cg.strokePath()
    }
}
