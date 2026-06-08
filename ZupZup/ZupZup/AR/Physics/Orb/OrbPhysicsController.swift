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
            motionResolver.updateOrbPhysics(
                trackedOrb,
                floorY: floorY,
                deltaTime: deltaTime,
                now: now
            )
        }
    }

    func removeAll(from arView: ARView?) {
        for trackedOrb in trackedOrbs {
            arView?.scene.removeAnchor(trackedOrb.anchor)
        }
        trackedOrbs.removeAll()
    }

    private func releaseOrbAfterWaitingPeriod(_ trackedOrb: TrackedOrb) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: OrbPhysicsSettings.releaseDelayNanoseconds)

            guard trackedOrbs.contains(where: { $0 === trackedOrb }) else {
                return
            }

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
}
