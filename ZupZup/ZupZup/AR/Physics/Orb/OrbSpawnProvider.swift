//
//  OrbSpawnProvider.swift
//  ZupZup
//
// 카메라 기준 구슬 생성 위치를 계산하는 파일

import simd

@MainActor
protocol OrbSpawnProviding {
    func spawnPosition(cameraTransform: simd_float4x4, floorY: Float?) -> SIMD3<Float>
}

struct CameraOrbSpawnProvider: OrbSpawnProviding {
    func spawnPosition(cameraTransform: simd_float4x4, floorY: Float?) -> SIMD3<Float> {
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let cameraForward = normalize(-SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        ))
        let cameraDown = normalize(-SIMD3<Float>(
            cameraTransform.columns.1.x,
            cameraTransform.columns.1.y,
            cameraTransform.columns.1.z
        ))

        var spawnPosition = cameraPosition + cameraForward * 0.5 + cameraDown * 0.15

        if let floorY {
            spawnPosition.y = max(spawnPosition.y, floorY + 0.25)
        }

        return spawnPosition
    }
}
