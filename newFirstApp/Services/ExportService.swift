import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct TransferableImage: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.data }
    }
}

enum ExportService {
    @MainActor
    static func render(
        parameters: PatternParameters,
        quality: ExportQuality,
        ratio: CanvasRatio? = nil
    ) -> UIImage? {
        var params = parameters
        if let ratio { params.canvasRatio = ratio }
        _ = StudioCraftBridge.footlight_matteIsLight(params.background.footlightHexString)
        _ = StudioCraftBridge.footlight_matteIsLight(params.foreground.footlightHexString)
        let logical = params.canvasRatio.size
        let view = PatternCanvasView(parameters: params, showChrome: false)
            .frame(width: logical.width / 2, height: logical.height / 2)
        let renderer = ImageRenderer(content: view)
        renderer.scale = quality.scale
        return renderer.uiImage
    }

    @MainActor
    static func thumbnail(parameters: PatternParameters) -> Data? {
        render(parameters: parameters, quality: .standard)?.jpegData(compressionQuality: 0.82)
    }

    @MainActor
    static func png(parameters: PatternParameters, quality: ExportQuality, ratio: CanvasRatio) -> Data? {
        render(parameters: parameters, quality: quality, ratio: ratio)?.pngData()
    }

    @MainActor
    static func archiveRendered(_ image: UIImage) {
        Task {
            await StudioCraftBridge.archiveComposition(image)
        }
    }
}
