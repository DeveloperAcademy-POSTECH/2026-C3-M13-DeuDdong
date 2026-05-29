//
//  PhysicsSetup.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit

enum PhysicsSetup {
    static func applyDynamicBody(to entity: ModelEntity, shape: ShapeResource, mass: Float = 0.05) {
        let material = PhysicsMaterialResource.generate(
            staticFriction: 0.5,
            dynamicFriction: 0.5,
            restitution: 0.3
        )

        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            shapes: [shape],
            mass: mass,
            material: material,
            mode: .dynamic
        ))
    }

    static func applyStaticBody(to entity: ModelEntity, shape: ShapeResource) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            shapes: [shape],
            mass: 1,
            material: nil,
            mode: .static
        ))
    }
}
