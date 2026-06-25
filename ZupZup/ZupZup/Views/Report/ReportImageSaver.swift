import SwiftUI

@MainActor
func captureReportImage(collectedCount: Int) -> UIImage? {
    let renderer = ImageRenderer(content: ReportContentView(collectedCount: collectedCount))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}
