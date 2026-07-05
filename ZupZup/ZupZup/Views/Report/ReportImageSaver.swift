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
}
