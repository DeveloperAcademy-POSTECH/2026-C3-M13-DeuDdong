//
//  OrbMotionResolver.swift
//  ZupZup
//
// 구슬 낙하 후 바닥 접촉, 튐, 감속, 정착 등의 모션 보정 파일

import Foundation
import RealityKit

@MainActor
final class OrbMotionResolver {
    func updateOrbPhysics(
        _ trackedOrb: TrackedOrb,
        floorY: Float?,
        deltaTime: Float,
        now: CFTimeInterval
    ) {
        guard trackedOrb.state != .waiting else { return }
        guard trackedOrb.state != .grabbed else { return }

        clampOrbToFloorIfNeeded(trackedOrb, floorY: floorY)

        switch trackedOrb.state {
        case .waiting, .grabbed:
            break
        case .falling:
            handleFirstFloorTouchIfNeeded(trackedOrb, floorY: floorY, now: now)
        case .bounced:
            dampOrbVelocity(trackedOrb, linearDamping: 0.88, angularDamping: 0.82)
            settleOrbIfSlowEnough(trackedOrb, floorY: floorY, now: now)
        case .settled:
            keepOrbSettled(trackedOrb, floorY: floorY)
        }

        dampOrbIfTooFast(trackedOrb, deltaTime: deltaTime)
    }

    private func dampOrbVelocity(
        _ trackedOrb: TrackedOrb,
        linearDamping: Float,
        angularDamping: Float
    ) {
        guard var motion = trackedOrb.entity.components[PhysicsMotionComponent.self] else {
            return
        }

        motion.linearVelocity.x *= linearDamping
        motion.linearVelocity.z *= linearDamping
        motion.linearVelocity.y *= min(1, linearDamping + 0.08)
        motion.angularVelocity *= angularDamping
        trackedOrb.entity.components.set(motion)
    }

    private func dampOrbIfTooFast(_ trackedOrb: TrackedOrb, deltaTime: Float) {
        guard trackedOrb.state == .bounced,
              var motion = trackedOrb.entity.components[PhysicsMotionComponent.self] else {
            return
        }

        let horizontalVelocity = SIMD2<Float>(motion.linearVelocity.x, motion.linearVelocity.z)
        let horizontalSpeed = length(horizontalVelocity)

        if horizontalSpeed > 0.12 {
            let scale = max(0.12 / horizontalSpeed, 0.35)
            motion.linearVelocity.x *= scale
            motion.linearVelocity.z *= scale
        }

        let floorHoldDamping = pow(Float(0.42), deltaTime)
        motion.linearVelocity.x *= floorHoldDamping
        motion.linearVelocity.z *= floorHoldDamping
        motion.angularVelocity *= floorHoldDamping
        trackedOrb.entity.components.set(motion)
    }

    private func settleOrbIfSlowEnough(
        _ trackedOrb: TrackedOrb,
        floorY: Float?,
        now: CFTimeInterval
    ) {
        guard let motion = trackedOrb.entity.components[PhysicsMotionComponent.self] else {
            return
        }

        let linearSpeed = length(motion.linearVelocity)
        let angularSpeed = length(motion.angularVelocity)
        let hasBeenOnFloorLongEnough = now - (trackedOrb.touchedFloorTime ?? now) > 0.65

        guard hasBeenOnFloorLongEnough,
              linearSpeed < OrbPhysicsSettings.settledVelocityThreshold,
              angularSpeed < OrbPhysicsSettings.settledAngularVelocityThreshold else {
            return
        }

        trackedOrb.state = .settled
        trackedOrb.settledTime = now
        keepOrbSettled(trackedOrb, floorY: floorY)
    }

    private func keepOrbSettled(_ trackedOrb: TrackedOrb, floorY: Float?) {
        guard let floorY else {
            return
        }

        let worldPosition = orbWorldPosition(trackedOrb)
        setOrbWorldPosition(
            trackedOrb,
            SIMD3<Float>(worldPosition.x, floorY + trackedOrb.radius, worldPosition.z)
        )

        var body = trackedOrb.entity.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent(
            massProperties: .init(mass: OrbPhysicsSettings.orbMass),
            material: OrbPhysicsSettings.settledOrbPhysicsMaterial,
            mode: .kinematic
        )
        body.mode = .kinematic
        body.material = OrbPhysicsSettings.settledOrbPhysicsMaterial
        trackedOrb.entity.components.set(body)
        trackedOrb.entity.components.set(PhysicsMotionComponent(
            linearVelocity: .zero,
            angularVelocity: .zero
        ))
    }

    private func handleFirstFloorTouchIfNeeded(
        _ trackedOrb: TrackedOrb,
        floorY: Float?,
        now: CFTimeInterval
    ) {
        guard let floorY else {
            return
        }

        let floorContactY = floorY + trackedOrb.radius
        let worldPosition = orbWorldPosition(trackedOrb)

        guard shouldSettleOnFloor(trackedOrb, floorContactY: floorContactY) else {
            return
        }

        trackedOrb.hasBounced = true
        trackedOrb.state = .settled
        trackedOrb.touchedFloorTime = now
        trackedOrb.settledTime = now

        setOrbWorldPosition(
            trackedOrb,
            SIMD3<Float>(worldPosition.x, floorContactY, worldPosition.z)
        )

        keepOrbSettled(trackedOrb, floorY: floorY)
    }

    private func shouldSettleOnFloor(
        _ trackedOrb: TrackedOrb,
        floorContactY: Float
    ) -> Bool {
        let worldPosition = orbWorldPosition(trackedOrb)

        if worldPosition.y <= floorContactY + OrbPhysicsSettings.floorSettleTolerance {
            return true
        }

        guard let motion = trackedOrb.entity.components[PhysicsMotionComponent.self] else {
            return false
        }

        let isLowBounce = worldPosition.y <= floorContactY + OrbPhysicsSettings.bounceCatchTolerance
        return isLowBounce && motion.linearVelocity.y > 0
    }

    private func clampOrbToFloorIfNeeded(_ trackedOrb: TrackedOrb, floorY: Float?) {
        guard let floorY else {
            return
        }

        let floorContactY = floorY + trackedOrb.radius
        let worldPosition = orbWorldPosition(trackedOrb)

        guard worldPosition.y < floorContactY else {
            return
        }

        setOrbWorldPosition(
            trackedOrb,
            SIMD3<Float>(worldPosition.x, floorContactY, worldPosition.z)
        )

        guard var motion = trackedOrb.entity.components[PhysicsMotionComponent.self] else {
            return
        }

        motion.linearVelocity.y = max(motion.linearVelocity.y, 0)
        trackedOrb.entity.components.set(motion)
    }

    private func orbWorldPosition(_ trackedOrb: TrackedOrb) -> SIMD3<Float> {
        trackedOrb.entity.position(relativeTo: nil)
    }

    private func setOrbWorldPosition(_ trackedOrb: TrackedOrb, _ position: SIMD3<Float>) {
        trackedOrb.entity.setPosition(position, relativeTo: nil)
    }
}
