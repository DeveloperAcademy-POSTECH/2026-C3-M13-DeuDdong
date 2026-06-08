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

            orbEntity.move(
                to: brightTransform,
                relativeTo: orbEntity.parent,
                duration: 0.1,
                timingFunction: .easeInOut
            )
            try? await Task.sleep(nanoseconds: 100_000_000)

            orbEntity.move(
                to: baseTransform,
                relativeTo: orbEntity.parent,
                duration: 0.12,
                timingFunction: .easeInOut
            )
        }
    }
}
