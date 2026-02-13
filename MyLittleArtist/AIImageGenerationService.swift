import Foundation
import UIKit

enum ImageGenerationError: Error {
    case unsupported
    case failed
}

final class AIImageGenerationService: ImageGenerationService {
    private let fallbackRenderer = ParametricCarTemplateRenderer()

    func generateImage(for prompt: String, size: CGSize) async throws -> Data {
        if #available(iOS 18.0, *) {
            // TODO: Replace with real Foundation Models image generation API when available.
            // Pseudocode example:
            // let data = try await FoundationModels.generateImage(prompt: prompt, size: size)
            // return data
            // For now, we simulate failure to exercise fallback.
        }
        // Fallback: Heuristic parametric rendering for vehicles if detected
        let lowered = prompt.lowercased()
        let isVehicle = lowered.contains("car") || lowered.contains("truck") || lowered.contains("vehicle")
        if isVehicle {
            let data = fallbackRenderer.renderTemplate(category: .vehicles, keywords: ["car"], size: size, strokeWidth: max(2, min(size.width, size.height) * 0.02))
            if !data.isEmpty { return data }
        }
        throw ImageGenerationError.failed
    }
}
