//
//  OnboardingPermissionManager.swift
//  Zupzup
//
//  Created by Codex on 6/5/26.
//

import AVFoundation
import Observation
import Photos
import Speech

@Observable
final class OnboardingPermissionManager {
    var hasRequiredPermissions = false
    var isRequesting = false
    var message = ""
    var shouldShowSettingsButton = false

    var primaryButtonTitle: String {
        if isRequesting {
            return "권한 확인 중"
        }

        return hasRequiredPermissions ? "시작하기" : "권한 허용하기"
    }

    @MainActor
    func refreshStatuses() {
        let result = currentPermissionResult()
        hasRequiredPermissions = result.requiredGranted

        if result.requiredGranted {
            message = ""
            shouldShowSettingsButton = false
        }
    }

    @MainActor
    func requestPermissions() async -> Bool {
        isRequesting = true
        shouldShowSettingsButton = false
        message = "권한을 확인하고 있습니다."

        let currentResult = currentPermissionResult()
        guard !currentResult.requiredGranted else {
            hasRequiredPermissions = true
            isRequesting = false
            message = ""
            return true
        }

        let result = await requestOnboardingPermissions()

        hasRequiredPermissions = result.requiredGranted
        isRequesting = false

        if result.requiredGranted {
            message = ""
            return true
        }

        message = "\(result.missingRequiredPermissionsText) 권한이 필요합니다. 설정에서 권한을 허용해주세요."
        shouldShowSettingsButton = true
        return false
    }

    private func currentPermissionResult() -> OnboardingPermissionResult {
        let cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let microphoneGranted = AVAudioApplication.shared.recordPermission == .granted
        let speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized

        return makePermissionResult(
            cameraGranted: cameraGranted,
            microphoneGranted: microphoneGranted,
            speechGranted: speechGranted
        )
    }

    private func requestOnboardingPermissions() async -> OnboardingPermissionResult {
        let cameraGranted = await requestCameraPermission()
        let microphoneGranted = await requestMicrophonePermission()
        let speechGranted = await requestSpeechPermission()
        _ = await requestPhotoAddPermission()

        return makePermissionResult(
            cameraGranted: cameraGranted,
            microphoneGranted: microphoneGranted,
            speechGranted: speechGranted
        )
    }

    private func makePermissionResult(
        cameraGranted: Bool,
        microphoneGranted: Bool,
        speechGranted: Bool
    ) -> OnboardingPermissionResult {
        let missingRequiredPermissions = [
            cameraGranted ? nil : "카메라",
            microphoneGranted ? nil : "마이크",
            speechGranted ? nil : "음성 인식"
        ].compactMap { $0 }

        return OnboardingPermissionResult(missingRequiredPermissions: missingRequiredPermissions)
    }

    private func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func requestSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func requestPhotoAddPermission() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

private struct OnboardingPermissionResult {
    let missingRequiredPermissions: [String]

    var requiredGranted: Bool {
        missingRequiredPermissions.isEmpty
    }

    var missingRequiredPermissionsText: String {
        missingRequiredPermissions.joined(separator: ", ")
    }
}
