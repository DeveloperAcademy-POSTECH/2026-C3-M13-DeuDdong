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
        triggerBurstEffect(on: entity)
        scheduleRemoval(of: anchor, from: scene)
    }

    private static func particleName(for emotion: EmotionType) -> String {
        emotion.rawValue.capitalized + "Particle"
    }

    private static func loadEntity(for emotion: EmotionType) -> Entity? {
        let name = particleName(for: emotion)
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

    private static func triggerBurstEffect(on entity: Entity) {
            // 1. 파일 내부(자식, 손자 노드 포함 전체)를 싹 뒤져서
            // "ParticleEmitterComponent" 기능을 가진 첫 번째 물체를 이름 안 보고 그냥 집어옵니다.
            if let emitterEntity = findAnyEmitter(in: entity),
               var emitter = emitterEntity.components[ParticleEmitterComponent.self] {
                emitter.burst()
                emitterEntity.components[ParticleEmitterComponent.self] = emitter
                Logger.particle.info("🎉 [성공] 이름 상관없이 파일 안의 파티클을 찾아 터뜨렸습니다! (찾은 물체 이름: \(emitterEntity.name))")
                return
            }
            Logger.particle.error("❌ [실패] 이 .usda 파일 안에는 '파티클' 기능 자체가 들어있지 않습니다!")
    }
    
    private static func findAnyEmitter(in entity: Entity) -> Entity? {
            // 자기 자신에게 파티클 기능이 있다면 즉시 반환
            if entity.components.has(ParticleEmitterComponent.self) {
                return entity
            }
            // 자식들을 돌면서 파티클 기능이 있는 녀석이 나오면 이름 불문하고 바로 반환
            for child in entity.children {
                if let found = findAnyEmitter(in: child) {
                    return found
                }
            }
            return nil
    }

    private static func scheduleRemoval(of anchor: AnchorEntity, from scene: Scene) {
        Task {
            try? await Task.sleep(for: .seconds(3))
            anchor.removeFromParent()
        }
    }
}
