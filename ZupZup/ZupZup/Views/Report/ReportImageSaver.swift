import Photos
import SwiftUI

enum ReportImageSaver {
    enum PermissionResult {
        case granted
        case denied
    }

    static func requestPermission() async -> PermissionResult {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return .granted
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited ? .granted : .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    @MainActor
    static func renderImage(from summary: ReportSummary) -> UIImage? {
        let renderer = ImageRenderer(content: ReportContentView(summary: summary, usesStaticBowl: true))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    static func save(_ image: UIImage) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
