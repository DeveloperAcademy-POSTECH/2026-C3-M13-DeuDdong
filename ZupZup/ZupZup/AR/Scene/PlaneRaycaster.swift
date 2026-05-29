//
//  PlaneRaycaster.swift -> 인식한 좌표를 RealityKit(3D)에 맞게 바꿔줌
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit
import CoreGraphics
import simd

enum PlaneRaycaster {
    static func horizontalPlanePosition(from screenPoint: CGPoint, in arView: ARView) -> SIMD3<Float>? {
        arView.raycast(
            from: screenPoint,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        ).first?.worldTransform.translation
    }
}

extension ARPlaneAnchor {
    var worldCenter: SIMD3<Float> {
        let localCenter = SIMD4<Float>(center.x, center.y, center.z, 1)
        let worldCenter = transform * localCenter
        return SIMD3<Float>(worldCenter.x, worldCenter.y, worldCenter.z)
    }
}

private extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
