//
//  ParticleBurst.swift
//  ZupZup
//

import RealityKit
import Foundation
import OSLog

@MainActor
enum ParticleBurst {

    static func burst(for emotion: EmotionType, at position: SIMD3<Float>, in scene: Scene) {
        guard let entity = loadEntity(for: emotion) else { return }
        let anchor = spawn(entity: entity, at: position, in: scene)
        scheduleRemoval(of: anchor, from: scene)
    }

    private static func loadEntity(for emotion: EmotionType) -> Entity? {
        let name = emotion.rawValue.capitalized + "Particle"
        guard let entity = try? Entity.load(named: name) else {
            Logger.particle.error("'\(name)' 로드 실패")
            return nil
        }
        return entity
    }

    private static func spawn(entity: Entity, at position: SIMD3<Float>, in scene: Scene) -> AnchorEntity {
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        scene.addAnchor(anchor)
        return anchor
    }

    private static func scheduleRemoval(of anchor: AnchorEntity, from scene: Scene) {
        Task {
            try? await Task.sleep(for: .seconds(3))
            anchor.removeFromParent()
        }
    }
}
