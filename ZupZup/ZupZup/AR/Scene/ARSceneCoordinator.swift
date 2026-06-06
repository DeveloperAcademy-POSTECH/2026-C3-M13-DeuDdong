//
//  ARSceneCoordinator.swift -> 이 친구가 사람으로 치면 뇌(Brain)입니다!
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit

final class ARSceneCoordinator: NSObject, ARSessionDelegate {
    private let sessionManager: ARSessionManager
    private let placementManager: PlacementManager
    private let emotionRuntime: EmotionRuntimeManaging
    private let handTrackingManager = HandTrackingManager.shared
    private var planeVisualizer: PlaneVisualizer?
    private var onPlaneStateChange: (ARState) -> Void
    private weak var arView: ARView?
    private var hasPlacedDemoObjects = false
    private var lastHandPoseUpdateTime: TimeInterval = 0
    private var wasPinching = false
    private var lastPinchSeenTime: TimeInterval = 0
    private let pinchLostGraceDuration: TimeInterval = 0.3
    private var isHandPoseRequestInFlight = false
    
    private let handPoseQueue = DispatchQueue(label: "com.zupzup.handPose")
    
    init(
        sessionManager: ARSessionManager,
        placementManager: PlacementManager,
        emotionRuntime: EmotionRuntimeManaging,
        onPlaneStateChange: @escaping (ARState) -> Void
    ) {
        self.sessionManager = sessionManager
        self.placementManager = placementManager
        self.emotionRuntime = emotionRuntime
        self.onPlaneStateChange = onPlaneStateChange
    }
    // ARSceneCoordinator는 두뇌같은 역할이죠. 그치만 멍청한 친구 같아요. 왜 자꾸 말을 안 듣니?
    func install(on arView: ARView) {
        self.arView = arView
        sessionManager.attach(to: arView)
        placementManager.attach(to: arView)
        planeVisualizer = PlaneVisualizer(arView: arView)
        arView.session.delegate = self
        sessionManager.startSession()
    }

    #if DEBUG
    func triggerDebugBurst(emotion: EmotionType = .affection) {
        guard let arView else { return }
        let col2 = arView.cameraTransform.matrix.columns.2
        let forward = SIMD3<Float>(col2.x, col2.y, col2.z)
        let position = arView.cameraTransform.translation + forward * -3.0
        ParticleBurst.burst(for: emotion, at: position, in: arView.scene)
    }
    #endif

    func updatePlaneStateHandler(_ handler: @escaping (ARState) -> Void) {
        onPlaneStateChange = handler
    }

    func resetScene() {
        hasPlacedDemoObjects = false
        planeVisualizer?.removeAll()
        placementManager.clearScene()
        onPlaneStateChange(.searching)
        sessionManager.resetSession()
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        updatePlaneVisuals(for: anchors, action: .add)
        handlePlaneAnchors(anchors)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) { // ARAnchor 업데이트 용
        updatePlaneVisuals(for: anchors, action: .update)
        handlePlaneAnchors(anchors)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) { // 카메라 프레임 업데이트 용
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastHandPoseUpdateTime > 0.1, !isHandPoseRequestInFlight else { return }
        
        lastHandPoseUpdateTime = currentTime
        isHandPoseRequestInFlight = true
        
        let pixelBuffer = frame.capturedImage
        
        handPoseQueue.async { [weak self] in
            let result = HandTrackingManager.detectHandPose(from: pixelBuffer)
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                defer { // 이 블록 끝나는 마지막 순간에 자동 실행
                    self.isHandPoseRequestInFlight = false
                }
                
                HandTrackingManager.shared.apply(result)
                self.handleHandGesture()
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            planeVisualizer?.remove(anchor.identifier)
        }
    }
    
    
    private func updatePlaneVisuals(for anchors: [ARAnchor], action: PlaneVisualAction) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            
            switch action {
            case .add:
                planeVisualizer?.add(planeAnchor)
            case .update:
                planeVisualizer?.update(planeAnchor)
            }
        }
    }
    
    private func handlePlaneAnchors(_ anchors: [ARAnchor]) {
        guard let horizontalPlane = anchors.compactMap({ $0 as? ARPlaneAnchor })
            .first(where: { $0.alignment == .horizontal }) else {
            return
        }
        
        onPlaneStateChange(.ready)
        
        guard !hasPlacedDemoObjects else { return }
        hasPlacedDemoObjects = true
        placementManager.placeDemoObjects(on: horizontalPlane)
    }
    
    private func handleHandGesture() {
        let handTrackingManager = HandTrackingManager.shared
        
        switch handTrackingManager.currentGesture {
        case .pinched:
            guard let indexTipPoint = handTrackingManager.indexTipPoint,
                  let screenPoint = placementManager.screenPoint(fromNormalizedPoint: indexTipPoint)
            else {
                return
            }
            
            lastPinchSeenTime = Date().timeIntervalSince1970
            
            if !wasPinching {
                placementManager.selectOrb(at: screenPoint)
                wasPinching = true
                return
            }
            
            if placementManager.hasSelectedOrb {
                placementManager.moveSelectedOrb(to: screenPoint)
            }
            
            wasPinching = true
            
        case .apart:
            releaseIfNeeded()
            
        case .none:
            let elapsedSincePinch = Date().timeIntervalSince1970 - lastPinchSeenTime
            
            if elapsedSincePinch > pinchLostGraceDuration {
                releaseIfNeeded()
            }
        }
    }
    
    private func releaseIfNeeded() {
        if wasPinching || placementManager.hasSelectedOrb {
            placementManager.releaseSelectedOrb()
        }
        
        wasPinching = false
    }
}

private enum PlaneVisualAction {
    case add
    case update
}
