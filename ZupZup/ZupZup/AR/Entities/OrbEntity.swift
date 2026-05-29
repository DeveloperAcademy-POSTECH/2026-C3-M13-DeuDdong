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
        let shape = ShapeResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: emotion.color, roughness: 0.50, isMetallic: false)
        let orb = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )

        orb.name = "Orb_\(emotion.rawValue)"
        PhysicsSetup.applyDynamicBody(to: orb, shape: shape)
        return orb
    }
}
