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
        return orb
    }
}
