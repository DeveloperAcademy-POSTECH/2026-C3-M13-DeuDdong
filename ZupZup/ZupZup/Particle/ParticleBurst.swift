//
//  ParticleBurst.swift
//  ZupZup
//

import RealityKit
import Foundation

@MainActor
enum ParticleBurst {
    
    static func burst(for emotion: EmotionType, at position: SIMD3<Float>, in scene: Scene) {
        let name = emotion.rawValue.capitalized + "Particle"
        guard let entity = try? Entity.load(named: name) else {
            print("ParticleBurst: \(name) 로드 실패")
            return
        }

        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        scene.addAnchor(anchor)

        Task {
            try? await Task.sleep(for: .seconds(3))
            anchor.removeFromParent()
        }
    }
}
