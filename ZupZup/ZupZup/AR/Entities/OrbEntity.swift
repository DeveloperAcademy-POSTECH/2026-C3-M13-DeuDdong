//
//  OrbEntity.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit
internal import UIKit
import ZupZupContent

enum OrbEntity {
    static let radius: Float = 0.035

    static func makeOrb(emotion: EmotionType) -> ModelEntity {
        let orb = makeBaseOrb(emotion: emotion, radius: radius)
        let shape = ShapeResource.generateSphere(radius: radius)
        PhysicsSetup.applyKinematicBody(to: orb, shape: shape)
        return orb
    }

    static func makeWaitingOrb(emotion: EmotionType) -> ModelEntity {
        let orb = makeBaseOrb(emotion: emotion, radius: OrbPhysicsSettings.orbRadius)
        let shape = ShapeResource.generateSphere(radius: OrbPhysicsSettings.orbRadius)
        OrbPhysicsSettings.applyWaitingOrbBody(to: orb, shape: shape)
        return orb
    }

    private static func makeBaseOrb(emotion: EmotionType, radius: Float) -> ModelEntity {
        if let visual = loadDesignedOrbVisual(for: emotion) {
            let orb = ModelEntity()
            orb.name = "Orb_\(emotion.rawValue)"
            orb.addChild(visual)
            fitVisual(visual, in: orb, targetRadius: radius)
            return orb
        }

        let fallbackOrb = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [stableMaterial(for: emotion)]
        )
        fallbackOrb.name = "Orb_\(emotion.rawValue)"
        return fallbackOrb
    }

    static func makeDebugOrb(emotion: EmotionType) -> ModelEntity {
        let shape = ShapeResource.generateSphere(radius: radius)
        let orb = makeBaseOrb(emotion: emotion, radius: radius)
        orb.name = "DebugOrb_\(emotion.rawValue)"
        orb.components.set(CollisionComponent(shapes: [shape]))

        return orb
    }

    private static func stableMaterial(for emotion: EmotionType) -> SimpleMaterial {
        SimpleMaterial(color: stableColor(for: emotion), roughness: 0.34, isMetallic: false)
    }

    private static func stableColor(for emotion: EmotionType) -> UIColor {
        switch emotion {
        case .praise:
            UIColor(red: 0.47, green: 0.88, blue: 0.38, alpha: 1.0)
        case .encouragement:
            UIColor(red: 1.00, green: 0.82, blue: 0.22, alpha: 1.0)
        case .affection:
            UIColor(red: 1.00, green: 0.35, blue: 0.67, alpha: 1.0)
        case .gratitude:
            UIColor(red: 0.34, green: 0.62, blue: 1.00, alpha: 1.0)
        case .empathy:
            UIColor(red: 0.65, green: 0.42, blue: 1.00, alpha: 1.0)
        }
    }

    private static func loadDesignedOrbVisual(for emotion: EmotionType) -> Entity? {
        do {
            let visual = try Entity.load(named: designedOrbModelName(for: emotion), in: zupZupContentBundle)
            visual.name = "OrbVisual_\(emotion.rawValue)"
            stripRuntimePhysics(from: visual)
            return visual
        } catch {
            return nil
        }
    }

    private static func stripRuntimePhysics(from entity: Entity) {
        entity.components.remove(CollisionComponent.self)
        entity.components.remove(PhysicsBodyComponent.self)
        entity.components.remove(PhysicsMotionComponent.self)

        for child in entity.children {
            stripRuntimePhysics(from: child)
        }
    }

    private static func fitVisual(_ visual: Entity, in parent: Entity, targetRadius: Float) {
        visual.position = .zero
        visual.scale = SIMD3<Float>(repeating: 1)

        let bounds = visual.visualBounds(relativeTo: parent)
        let maxExtent = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)

        guard maxExtent > 0 else { return }

        let scale = (targetRadius * 2) / maxExtent
        visual.scale = SIMD3<Float>(repeating: scale)

        let scaledBounds = visual.visualBounds(relativeTo: parent)
        visual.position -= scaledBounds.center
    }

    private static func designedOrbModelName(for emotion: EmotionType) -> String {
        switch emotion {
        case .praise:
            "Balls/PraiseBall"
        case .encouragement:
            "Balls/EncouragementBall"
        case .affection:
            "Balls/AffectionBall"
        case .gratitude:
            "Balls/GratitudeBall"
        case .empathy:
            "Balls/EmpathyBall"
        }
    }
}
