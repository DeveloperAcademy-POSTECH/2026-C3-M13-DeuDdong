//
//  ParticleBurst.swift
//  ZupZup
//

import RealityKit
import OSLog

@MainActor
enum ParticleBurst {
    private static var cachedEmitters: [EmotionType: (anchor: AnchorEntity, entity: Entity)] = [:]

    static func burst(for emotion: EmotionType, at position: SIMD3<Float>, in scene: Scene) {
        Task {
            guard let cached = await cachedEmitter(for: emotion, in: scene) else { return }

            cached.anchor.move(to: Transform(translation: position), relativeTo: nil)
            triggerBurstEffect(on: cached.entity)
        }
    }

    private static func cachedEmitter(
        for emotion: EmotionType,
        in scene: Scene
    ) async -> (anchor: AnchorEntity, entity: Entity)? {
        if let cached = cachedEmitters[emotion] {
            return cached
        }

        guard let entity = await loadEntity(for: emotion) else { return nil }

        let anchor = AnchorEntity(world: .zero)
        entity.position = .zero
        anchor.addChild(entity)
        scene.addAnchor(anchor)

        let cached = (anchor: anchor, entity: entity)
        cachedEmitters[emotion] = cached
        return cached
    }

    private static func loadEntity(for emotion: EmotionType) async -> Entity? {
        await EntityLoader.load(named: emotion.particleName)
    }

    private static func triggerBurstEffect(on entity: Entity) {
        if let emitterEntity = findAnyEmitter(in: entity),
           var emitter = emitterEntity.components[ParticleEmitterComponent.self] {
            emitter.burst()
            emitterEntity.components[ParticleEmitterComponent.self] = emitter
            FeedbackSoundPlayer.playParticleBurst()
            HapticManager.shared.playParticleBurst()
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
}
