//
//  OrbSpawnManager.swift
//  ZupZup
//
// 구슬 엔티티 및 앵커 생성 후 TrackedOrb 변환 파일

import ARKit
import RealityKit

@MainActor
final class OrbSpawnManager {
    private let spawnProvider: any OrbSpawnProviding

    init() {
        self.spawnProvider = CameraOrbSpawnProvider()
    }

    init(spawnProvider: any OrbSpawnProviding) {
        self.spawnProvider = spawnProvider
    }

    func createOrb(
        in arView: ARView,
        floorY: Float?,
        emotion: EmotionType? = nil
    ) -> TrackedOrb? {
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
            return nil
        }

        let orbEmotion = emotion ?? EmotionType.allCases.randomElement() ?? .praise
        let spawnPosition = spawnProvider.spawnPosition(
            cameraTransform: cameraTransform,
            floorY: floorY
        )
        let orbEntity = OrbEntity.makeWaitingOrb(emotion: orbEmotion)

        let anchor = AnchorEntity(world: spawnPosition)
        anchor.name = "OrbAnchor_\(orbEmotion.rawValue)"
        anchor.addChild(orbEntity)
        arView.scene.addAnchor(anchor)
        ParticleBurst.burst(for: orbEmotion, at: spawnPosition, in: arView.scene)
        return TrackedOrb(anchor: anchor, entity: orbEntity)
    }
}
