//
//  OrbSpawnManager.swift
//  ZupZup
//
// 구슬 엔티티 및 앵커 생성 후 TrackedOrb 변환 파일

import ARKit
import RealityKit
import simd

@MainActor
final class OrbSpawnManager {
    func createOrb(
        in arView: ARView,
        floorY: Float?,
        emotion: EmotionType? = nil,
        mouthNormalizedPoint: CGPoint? = nil
    ) -> TrackedOrb? {
        guard let frame = arView.session.currentFrame else { return nil }

        let orbEmotion = emotion ?? EmotionType.allCases.randomElement() ?? .praise

        var spawnPosition: SIMD3<Float>
        if let normalizedPoint = mouthNormalizedPoint,
           let worldPos = MouthWorldPositionEstimator.worldPosition(
               for: normalizedPoint, frame: frame, floorY: floorY
           ) {
            spawnPosition = worldPos
        } else {
            spawnPosition = cameraSpawnPosition(from: frame.camera.transform, floorY: floorY)
        }

        let orbEntity = OrbEntity.makeWaitingOrb(emotion: orbEmotion)
        let orbRadius = OrbEntity.collisionRadius(for: orbEntity)
        orbEntity.position = .zero

        if let floorY {
            spawnPosition.y = max(
                spawnPosition.y,
                floorY + orbRadius + OrbPhysicsSettings.spawnClearanceAboveOrb
            )
        }

        let anchor = AnchorEntity(world: spawnPosition)
        anchor.name = "OrbAnchor_\(orbEmotion.rawValue)"
        anchor.addChild(orbEntity)
        arView.scene.addAnchor(anchor)
        let burstPosition = behindPersonPosition(from: spawnPosition, camera: frame.camera)
        ParticleBurst.burst(for: orbEmotion, at: burstPosition, in: arView.scene)
        return TrackedOrb(anchor: anchor, entity: orbEntity, radius: orbRadius)
    }

    private func behindPersonPosition(from facePosition: SIMD3<Float>, camera: ARCamera) -> SIMD3<Float> {
        let cameraPos = SIMD3<Float>(
            camera.transform.columns.3.x,
            camera.transform.columns.3.y,
            camera.transform.columns.3.z
        )
        let directionToFace = normalize(facePosition - cameraPos)
        return facePosition + directionToFace * 0.5
    }

    private func cameraSpawnPosition(from cameraTransform: simd_float4x4, floorY: Float?) -> SIMD3<Float> {
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

        var position = cameraPosition + cameraForward * 0.5 + cameraDown * 0.15

        if let floorY {
            position.y = max(position.y, floorY + OrbPhysicsSettings.minimumSpawnHeightAboveFloor)
        }

        return position
    }
}
