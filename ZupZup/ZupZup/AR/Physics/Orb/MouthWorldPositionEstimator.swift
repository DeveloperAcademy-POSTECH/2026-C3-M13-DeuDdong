//
//  MouthWorldPositionEstimator.swift
//  ZupZup
//
// FaceTracker가 .right orientation으로 처리한 결과로 얻은 정규화 초상화 좌표(x: 0=left→1=right, y: 0=top→1=bottom)를
// 카메라 intrinsics 기반 ray를 이용해 ARFrame의 3D 월드 좌표로 변환한다.
// LiDAR 지원 기기에서는 sceneDepth로 실제 깊이를 사용하고, 미지원 기기는 0.7m로 fallback한다.

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

        // 카메라 공간 방향 벡터 (정규화 전) — z축 깊이→반경 거리 변환에도 사용
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

        // sceneDepth는 광학축 기준 z깊이(m)를 저장한다.
        // direction은 광학축과 각도가 있으므로 실제 거리(radial) = z깊이 × |dirCamera|로 보정한다.
        let depth: Float
        if let depthMap = frame.sceneDepth?.depthMap,
           let zDepth = sampleDepth(imageCol: imageCol, imageRow: imageRow, imageSize: imageSize, from: depthMap) {
            depth = zDepth * length(dirCamera)
        } else {
            depth = 0.7
        }

        var position = cameraPos + direction * depth

        if let floorY {
            position.y = max(position.y, floorY + OrbPhysicsSettings.minimumSpawnHeightAboveFloor)
        }

        return position
    }

    // depthMap(CVPixelBuffer, Float32)에서 카메라 이미지 픽셀 좌표에 해당하는 깊이값을 읽는다.
    private static func sampleDepth(
        imageCol: Float,
        imageRow: Float,
        imageSize: CGSize,
        from depthMap: CVPixelBuffer
    ) -> Float? {
        let depthWidth = CVPixelBufferGetWidth(depthMap)
        let depthHeight = CVPixelBufferGetHeight(depthMap)

        // 카메라 이미지 좌표 → 정규화 → depthMap 픽셀 좌표
        let depthX = Int(imageCol / Float(imageSize.width) * Float(depthWidth))
        let depthY = Int(imageRow / Float(imageSize.height) * Float(depthHeight))

        guard depthX >= 0 && depthX < depthWidth,
              depthY >= 0 && depthY < depthHeight else { return nil }

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return nil }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let offset = depthY * bytesPerRow + depthX * MemoryLayout<Float32>.size
        let zDepth = base.load(fromByteOffset: offset, as: Float32.self)

        guard zDepth.isFinite && zDepth > 0.1 else { return nil }
        return zDepth
    }
}
