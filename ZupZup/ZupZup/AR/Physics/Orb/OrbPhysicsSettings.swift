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
    static let floorSettleTolerance: Float = 0.025
    static let bounceCatchTolerance: Float = 0.12
    static let settledVelocityThreshold: Float = 0.025
    static let settledAngularVelocityThreshold: Float = 0.2
    static let releaseDelayNanoseconds: UInt64 = 260_000_000
    static let initialDropVelocity = SIMD3<Float>(0, -0.75, 0)
    static let minimumSpawnHeightAboveFloor: Float = 0.18

    static var orbPhysicsMaterial: PhysicsMaterialResource {
        .generate(staticFriction: 0.98, dynamicFriction: 0.96, restitution: 0)
    }

    static var floorPhysicsMaterial: PhysicsMaterialResource {
        .generate(staticFriction: 0.98, dynamicFriction: 0.96, restitution: 0)
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
