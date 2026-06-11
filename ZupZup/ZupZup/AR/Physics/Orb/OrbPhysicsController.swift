//
//  OrbPhysicsController.swift
//  ZupZup
//
// 물리 작용 전반 담당 컨트롤러 파일, tracked orb 목록 및 낙하 전환을 관리

import Foundation
import RealityKit

@MainActor
final class OrbPhysicsController {
    private(set) var trackedOrbs: [TrackedOrb] = []
    private let motionResolver = OrbMotionResolver()
    private let feedbackPresenter = OrbFeedbackPresenter()
    private var interactingOrbIDs = Set<ObjectIdentifier>()

    var hasOrbs: Bool {
        !trackedOrbs.isEmpty
    }

    func addOrb(_ trackedOrb: TrackedOrb) {
        trackedOrbs.append(trackedOrb)
        feedbackPresenter.playSparklePulse(on: trackedOrb.entity)
        releaseOrbAfterWaitingPeriod(trackedOrb)
    }

    func updateOrbs(
        floorY: Float?,
        deltaTime: Float,
        now: CFTimeInterval,
        playAreaCenter _: SIMD3<Float>?
    ) {
        for trackedOrb in trackedOrbs {
            guard !isInteracting(with: trackedOrb.entity) else {
                continue
            }

            motionResolver.updateOrbPhysics(
                trackedOrb,
                floorY: floorY,
                deltaTime: deltaTime,
                now: now
            )
        }
    }

    func beginInteraction(with entity: ModelEntity) {
        guard let trackedOrb = trackedOrb(matching: entity) else {
            return
        }

        interactingOrbIDs.insert(ObjectIdentifier(entity))
        trackedOrb.hasManualInteraction = true
        FeedbackSoundPlayer.playOrbGrabbed()
        HapticManager.shared.playOrbGrabbed()
        settleOrbForInteraction(trackedOrb)
    }

    func endInteraction(with entity: ModelEntity, floorY: Float?) {
        guard let trackedOrb = trackedOrb(matching: entity) else {
            return
        }

        interactingOrbIDs.remove(ObjectIdentifier(entity))

        if shouldResumeFalling(trackedOrb, floorY: floorY) {
            startFalling(trackedOrb)
            return
        }

        settleOrbForInteraction(trackedOrb)
    }

    func removeOrb(_ entity: ModelEntity) {
        interactingOrbIDs.remove(ObjectIdentifier(entity))
        trackedOrbs.removeAll { $0.entity === entity }
    }

    func removeAll(from arView: ARView?) {
        for trackedOrb in trackedOrbs {
            arView?.scene.removeAnchor(trackedOrb.anchor)
        }
        trackedOrbs.removeAll()
        interactingOrbIDs.removeAll()
    }

    private func releaseOrbAfterWaitingPeriod(_ trackedOrb: TrackedOrb) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: OrbPhysicsSettings.releaseDelayNanoseconds)

            guard trackedOrbs.contains(where: { $0 === trackedOrb }) else {
                return
            }

            guard !trackedOrb.hasManualInteraction,
                  !isInteracting(with: trackedOrb.entity) else {
                return
            }

            startFalling(trackedOrb)
        }
    }

    private func trackedOrb(matching entity: ModelEntity) -> TrackedOrb? {
        trackedOrbs.first { $0.entity === entity }
    }

    private func isInteracting(with entity: ModelEntity) -> Bool {
        interactingOrbIDs.contains(ObjectIdentifier(entity))
    }

    private func shouldResumeFalling(_ trackedOrb: TrackedOrb, floorY: Float?) -> Bool {
        guard let floorY else {
            return false
        }

        let worldY = trackedOrb.entity.position(relativeTo: nil).y
        return worldY > floorY + trackedOrb.radius + OrbPhysicsSettings.floorSettleTolerance
    }

    private func settleOrbForInteraction(_ trackedOrb: TrackedOrb) {
        trackedOrb.state = .settled
        var body = trackedOrb.entity.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent(
            massProperties: .init(mass: OrbPhysicsSettings.orbMass),
            material: OrbPhysicsSettings.settledOrbPhysicsMaterial,
            mode: .kinematic
        )
        body.massProperties = .init(mass: OrbPhysicsSettings.orbMass)
        body.material = OrbPhysicsSettings.settledOrbPhysicsMaterial
        body.mode = .kinematic
        trackedOrb.entity.components.set(body)
        trackedOrb.entity.components.set(PhysicsMotionComponent(
            linearVelocity: .zero,
            angularVelocity: .zero
        ))
    }

    private func startFalling(_ trackedOrb: TrackedOrb) {
        trackedOrb.state = .falling
        var body = trackedOrb.entity.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent(
            massProperties: .init(mass: OrbPhysicsSettings.orbMass),
            material: OrbPhysicsSettings.orbPhysicsMaterial,
            mode: .dynamic
        )
        body.massProperties = .init(mass: OrbPhysicsSettings.orbMass)
        body.material = OrbPhysicsSettings.orbPhysicsMaterial
        body.mode = .dynamic
        trackedOrb.entity.components.set(body)
        trackedOrb.entity.components.set(PhysicsMotionComponent(
            linearVelocity: OrbPhysicsSettings.initialDropVelocity,
            angularVelocity: .zero
        ))
    }
}
