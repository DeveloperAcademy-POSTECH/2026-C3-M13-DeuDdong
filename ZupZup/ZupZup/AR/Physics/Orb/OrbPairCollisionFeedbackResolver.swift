//
//  OrbPairCollisionFeedbackResolver.swift
//  ZupZup
//
// 구슬끼리 맞닿는 순간을 감지해 유리 충돌 효과음을 재생하는 파일

import Foundation
import RealityKit

@MainActor
final class OrbPairCollisionFeedbackResolver {
    private var previousPositions: [ObjectIdentifier: SIMD3<Float>] = [:]
    private var lastFeedbackTimes: [OrbPairKey: CFTimeInterval] = [:]

    func update(
        trackedOrbs: [TrackedOrb],
        deltaTime: Float,
        now: CFTimeInterval
    ) {
        guard trackedOrbs.count > 1 else {
            rememberPositions(for: trackedOrbs)
            return
        }

        pruneFeedbackHistory(now: now)
        playFeedbackForCollidingPairs(
            trackedOrbs: trackedOrbs,
            deltaTime: deltaTime,
            now: now
        )
        rememberPositions(for: trackedOrbs)
    }

    func reset() {
        previousPositions.removeAll()
        lastFeedbackTimes.removeAll()
    }

    private func playFeedbackForCollidingPairs(
        trackedOrbs: [TrackedOrb],
        deltaTime: Float,
        now: CFTimeInterval
    ) {
        for firstIndex in 0..<trackedOrbs.count {
            for secondIndex in (firstIndex + 1)..<trackedOrbs.count {
                playFeedbackIfNeeded(
                    first: trackedOrbs[firstIndex],
                    second: trackedOrbs[secondIndex],
                    deltaTime: deltaTime,
                    now: now
                )
            }
        }
    }

    private func playFeedbackIfNeeded(
        first: TrackedOrb,
        second: TrackedOrb,
        deltaTime: Float,
        now: CFTimeInterval
    ) {
        guard canPlayFeedback(for: first, and: second) else {
            return
        }

        let firstPosition = first.entity.position(relativeTo: nil)
        let secondPosition = second.entity.position(relativeTo: nil)
        let centerDistance = length(firstPosition - secondPosition)
        let contactDistance = first.radius + second.radius + OrbPhysicsSettings.orbPairCollisionPadding

        guard centerDistance <= contactDistance else {
            return
        }

        let relativeSpeed = length(
            estimatedVelocity(for: first, currentPosition: firstPosition, deltaTime: deltaTime)
                - estimatedVelocity(for: second, currentPosition: secondPosition, deltaTime: deltaTime)
        )

        guard relativeSpeed >= OrbPhysicsSettings.minimumOrbPairCollisionSpeed else {
            return
        }

        let pairKey = OrbPairKey(first: first.entity, second: second.entity)
        guard now - (lastFeedbackTimes[pairKey] ?? 0) >= OrbPhysicsSettings.orbPairCollisionSoundCooldown else {
            return
        }

        lastFeedbackTimes[pairKey] = now
        FeedbackSoundPlayer.playOrbCollision()
    }

    private func canPlayFeedback(for first: TrackedOrb, and second: TrackedOrb) -> Bool {
        first.state != .waiting || second.state != .waiting
    }

    private func estimatedVelocity(
        for trackedOrb: TrackedOrb,
        currentPosition: SIMD3<Float>,
        deltaTime: Float
    ) -> SIMD3<Float> {
        let entityID = ObjectIdentifier(trackedOrb.entity)
        let physicsVelocity = trackedOrb.entity.components[PhysicsMotionComponent.self]?.linearVelocity ?? .zero

        guard let previousPosition = previousPositions[entityID],
              deltaTime > 0 else {
            return physicsVelocity
        }

        let positionVelocity = (currentPosition - previousPosition) / deltaTime
        return length(positionVelocity) > length(physicsVelocity) ? positionVelocity : physicsVelocity
    }

    private func rememberPositions(for trackedOrbs: [TrackedOrb]) {
        let liveIDs = Set(trackedOrbs.map { ObjectIdentifier($0.entity) })
        previousPositions = previousPositions.filter { liveIDs.contains($0.key) }

        for trackedOrb in trackedOrbs {
            previousPositions[ObjectIdentifier(trackedOrb.entity)] = trackedOrb.entity.position(relativeTo: nil)
        }
    }

    private func pruneFeedbackHistory(now: CFTimeInterval) {
        lastFeedbackTimes = lastFeedbackTimes.filter {
            now - $0.value < OrbPhysicsSettings.orbPairCollisionFeedbackHistoryDuration
        }
    }
}

private struct OrbPairKey: Hashable {
    private let firstID: ObjectIdentifier
    private let secondID: ObjectIdentifier

    init(first: ModelEntity, second: ModelEntity) {
        let firstID = ObjectIdentifier(first)
        let secondID = ObjectIdentifier(second)

        if firstID.hashValue <= secondID.hashValue {
            self.firstID = firstID
            self.secondID = secondID
        } else {
            self.firstID = secondID
            self.secondID = firstID
        }
    }
}
