//
//  OrbEntity.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit

enum OrbEntity {
    static let radius: Float = 0.025

    static func makeOrb(emotion: EmotionType) -> ModelEntity {
        let orb = makeBaseOrb(emotion: emotion, radius: radius)
        let shape = ShapeResource.generateSphere(radius: radius)
        PhysicsSetup.applyDynamicBody(to: orb, shape: shape)
        return orb
    }

    static func makeWaitingOrb(emotion: EmotionType) -> ModelEntity {
        let orb = makeBaseOrb(emotion: emotion, radius: OrbPhysicsSettings.orbRadius)
        let shape = ShapeResource.generateSphere(radius: OrbPhysicsSettings.orbRadius)
        OrbPhysicsSettings.applyWaitingOrbBody(to: orb, shape: shape)
        return orb
    }

    private static func makeBaseOrb(emotion: EmotionType, radius: Float) -> ModelEntity {
        let material = SimpleMaterial(color: emotion.color, roughness: 0.50, isMetallic: false)
        let orb = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )

        orb.name = "Orb_\(emotion.rawValue)"
        PhysicsSetup.applyDynamicBody(to: orb, shape: shape) // collision shape 넣어야지 레이를 쐈을 때 구슬이 맞음
        return orb
    }

    static func makeDebugOrb(emotion: EmotionType) -> ModelEntity {
        let shape = ShapeResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: emotion.color, roughness: 0.50, isMetallic: false)
        let orb = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )

        orb.name = "DebugOrb_\(emotion.rawValue)"
        orb.components.set(CollisionComponent(shapes: [shape]))

        return orb
    }
}
