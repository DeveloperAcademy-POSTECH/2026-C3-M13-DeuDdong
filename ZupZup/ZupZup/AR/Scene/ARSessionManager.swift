//
//  ARSessionManager.swift -> AR 세션 설정 및 실행을 담당!
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit

@MainActor
final class ARSessionManager {
    private weak var arview: ARView?
    
    var isWorldTrackingSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }
    
    func attach(to arView: ARView) {
        self.arview = arView
        arView.automaticallyConfigureSession = false
        arView.renderOptions.insert(.disableMotionBlur)
    }
    
    func startSession() {
        guard isWorldTrackingSupported else { return }
        
        arview?.session.run(
            makeWorldTrackingConfiguration(),
            options: [.resetTracking, .removeExistingAnchors]
        )
    }
    
    func resetSession() {
        startSession()
    }
    
    func pauseSession() {
        arview?.session.pause()
    }

    func burst(emotion: EmotionType) {
        guard let arview else { return }
        let cameraPos = arview.cameraTransform.translation
        // 머리 위 1.5m에 스폰해서 눈 내리는 느낌
        let position = SIMD3<Float>(cameraPos.x, cameraPos.y + 1.5, cameraPos.z)
        ParticleBurst.burst(for: emotion, at: position, in: arview.scene)
    }
    
    private func makeWorldTrackingConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        return configuration
    }
}
