//
//  OrbFeedbackPresenter.swift
//  ZupZup
//
// 구슬 대기 중 scale pulse 연출 파일

import RealityKit

@MainActor
final class OrbFeedbackPresenter {
    func playSparklePulse(on orbEntity: ModelEntity) {
        Task { @MainActor in
            let baseTransform = orbEntity.transform
            var brightTransform = baseTransform
            brightTransform.scale = SIMD3<Float>(repeating: 1.18)

            let pulseCount = 4
            for _ in 0..<pulseCount {
                orbEntity.move(
                    to: brightTransform,
                    relativeTo: orbEntity.parent,
                    duration: 0.18,
                    timingFunction: .easeInOut
                )
                try? await Task.sleep(nanoseconds: 180_000_000)

                orbEntity.move(
                    to: baseTransform,
                    relativeTo: orbEntity.parent,
                    duration: 0.32,
                    timingFunction: .easeInOut
                )
                try? await Task.sleep(nanoseconds: 320_000_000)
            }

            orbEntity.move(to: baseTransform, relativeTo: orbEntity.parent, duration: 0.1)
        }
    }
}
