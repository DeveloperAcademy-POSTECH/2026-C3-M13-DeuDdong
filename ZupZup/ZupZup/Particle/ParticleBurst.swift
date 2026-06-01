//
//  ParticleBurst.swift
//  ZupZup
//

import RealityKit
import Foundation

@MainActor
enum ParticleBurst {
    
    // emotion에 해당하는 usdz 파티클을 position 위치에 스폰하고 3초 후 자동 제거
    static func burst(for emotion: EmotionType, at position: SIMD3<Float>, in scene: Scene) {
        let name = emotion.rawValue.capitalized + "Particle"
        guard let entity = try? Entity.load(named: name) else {
            print("ParticleBurst: \(name) 로드 실패")
            return
        }

        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        scene.addAnchor(anchor)

        // 파티클 재생 후 앵커를 씬에서 제거해 메모리 누수 방지
        Task {
            try? await Task.sleep(for: .seconds(3))
            anchor.removeFromParent()
        }
    }
}
