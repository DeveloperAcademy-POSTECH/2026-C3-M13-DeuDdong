import SwiftUI

enum ReportImageSaver {
    @MainActor
    static func capture(summary: ReportSummary, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: ReportContentView(summary: summary))
        renderer.scale = scale
        return renderer.uiImage
    }
}
