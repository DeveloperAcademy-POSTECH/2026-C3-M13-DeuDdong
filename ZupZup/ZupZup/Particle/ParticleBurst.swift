//
//  ParticleBurst.swift
//  ZupZup
//

import RealityKit
import Foundation
import OSLog
import ZupZupContent

@MainActor
enum ParticleBurst {

    static func burst(for emotion: EmotionType, at position: SIMD3<Float>, in scene: Scene) {
        Task {
            guard let entity = await loadEntity(for: emotion) else { return }
            let anchor = spawn(entity: entity, at: position, in: scene)
            triggerBurstEffect(on: entity)
            scheduleRemoval(of: anchor, from: scene)
        }
    }

    private static func particleName(for emotion: EmotionType) -> String {
        "Particles/" + emotion.rawValue.capitalized + "Particle"
    }

    private static func loadEntity(for emotion: EmotionType) async -> Entity? {
        let name = particleName(for: emotion)
        do {
            return try await Entity(named: name, in: ZupZupContentBundle)
        } catch {
            Logger.particle.error("'\(name)' 로드 실패: \(error)")
            return nil
        }
    }

    private static func spawn(entity: Entity, at position: SIMD3<Float>, in scene: Scene) -> AnchorEntity {
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        scene.addAnchor(anchor)
        return anchor
    }

    private static func triggerBurstEffect(on entity: Entity) {
        if let emitterEntity = findAnyEmitter(in: entity),
           var emitter = emitterEntity.components[ParticleEmitterComponent.self] {
            emitter.burst()
            emitterEntity.components[ParticleEmitterComponent.self] = emitter
            Logger.particle.info("[성공] 파티클을 찾아 터뜨렸습니다! (찾은 물체 이름: \(emitterEntity.name))")
            return
        }
        Logger.particle.error("[실패] .usda 파일 안에 파티클 기능이 없습니다!")
    }

    private static func findAnyEmitter(in entity: Entity) -> Entity? {
        if entity.components.has(ParticleEmitterComponent.self) {
            return entity
        }
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
