//
//  MouthWorldPositionEstimator.swift
//  ZupZup
//
// FaceTracker가 .right orientation으로 처리한 결과로 얻은 정규화 초상화 좌표(x: 0=left→1=right, y: 0=top→1=bottom)를
// 카메라 intrinsics 기반 ray를 이용해 ARFrame의 3D 월드 좌표로 변환한다.

import ARKit
import simd

enum MouthWorldPositionEstimator {
    static func worldPosition(
        for normalizedPortraitPoint: CGPoint,
        frame: ARFrame,
        floorY: Float?
    ) -> SIMD3<Float>? {
        let camera = frame.camera
        let intrinsics = camera.intrinsics
        let imageSize = camera.imageResolution

        // FaceTracker .right orientation 기준: portrait x → image row, portrait y → image col (반전)
        let imageCol = Float((1 - normalizedPortraitPoint.y) * imageSize.width)
        let imageRow = Float(normalizedPortraitPoint.x * imageSize.height)

        let focalX = intrinsics[0][0], focalY = intrinsics[1][1]
        let principalX = intrinsics[2][0], principalY = intrinsics[2][1]

        let dirCamera = SIMD3<Float>(
            (imageCol - principalX) / focalX,
            -((imageRow - principalY) / focalY),
            -1.0
        )

        let cameraTransform = camera.transform
        let dirWorld4 = cameraTransform * SIMD4<Float>(dirCamera.x, dirCamera.y, dirCamera.z, 0)
        let direction = normalize(SIMD3<Float>(dirWorld4.x, dirWorld4.y, dirWorld4.z))

        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        var position = cameraPos + direction * 0.7

        if let floorY {
            position.y = max(position.y, floorY + OrbPhysicsSettings.minimumSpawnHeightAboveFloor)
        }

        return position
    }
}
