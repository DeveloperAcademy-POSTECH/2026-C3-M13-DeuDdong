import Photos
import SwiftUI

enum ReportImageSaver {
    enum SaveResult {
        case success
        case permissionDenied
        case failure(any Error)
    }

    @MainActor
    static func capture(summary: ReportSummary, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: ReportContentView(summary: summary))
        renderer.scale = scale
        return renderer.uiImage
    }

    @MainActor
    static func saveToPhotos(summary: ReportSummary, scale: CGFloat = 3.0) async -> SaveResult {
        guard await ensurePermission() else { return .permissionDenied }
        guard let image = capture(summary: summary, scale: scale) else {
            return .failure(SaveError.captureFailed)
        }
        return await writeToLibrary(image: image)
    }

    private static func ensurePermission() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private static func writeToLibrary(image: UIImage) async -> SaveResult {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: .success)
                } else {
                    continuation.resume(returning: .failure(error ?? SaveError.unknown))
                }
            }
        }
    }

    private enum SaveError: Error {
        case captureFailed, unknown
    }
}
