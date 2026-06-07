//
//  OrbPhysicsSettings.swift
//  ZupZup
//
// 구슬 및 바닥 물리 상수와 physics body 적용을 돕는 파일

import RealityKit

enum OrbPhysicsSettings {
    static let orbRadius: Float = 0.025
    static let orbMass: Float = 0.18
    static let maximumOrbCount = 8
    static let playAreaRadius: Float = 0.8
    static let settledVelocityThreshold: Float = 0.025
    static let settledAngularVelocityThreshold: Float = 0.2

    static var orbPhysicsMaterial: PhysicsMaterialResource {
        .generate(staticFriction: 0.92, dynamicFriction: 0.86, restitution: 0.04)
    }

    static var floorPhysicsMaterial: PhysicsMaterialResource {
        .generate(staticFriction: 0.8, dynamicFriction: 0.6, restitution: 0.2)
    }

    static var settledOrbPhysicsMaterial: PhysicsMaterialResource {
        .generate(staticFriction: 0.98, dynamicFriction: 0.96, restitution: 0)
    }

    static func applyWaitingOrbBody(to entity: ModelEntity, shape: ShapeResource) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .init(mass: orbMass),
            material: orbPhysicsMaterial,
            mode: .kinematic
        ))
        entity.components.set(PhysicsMotionComponent(
            linearVelocity: .zero,
            angularVelocity: .zero
        ))
    }

    static func applyDynamicBody(to entity: ModelEntity, shape: ShapeResource, mass: Float = orbMass) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .init(mass: mass),
            material: orbPhysicsMaterial,
            mode: .dynamic
        ))
    }

    static func applyStaticBody(to entity: Entity, shape: ShapeResource) {
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(PhysicsBodyComponent(
            massProperties: .default,
            material: floorPhysicsMaterial,
            mode: .static
        ))
    }
}
