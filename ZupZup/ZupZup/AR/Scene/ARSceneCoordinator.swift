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
    private var lastHandPoseUpdateTime: TimeInterval = 0 // 마지막으로 AI 검사를 완료한 시각
    private var lastFaceTrackingUpdateTime: TimeInterval = 0
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

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updatePlaneVisuals(for: anchors, action: .update)
        handlePlaneAnchors(anchors)
    }

    // handTrackingManager와 ARView 연결
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTime = Date().timeIntervalSince1970 // 현재 시간 체크(스톱워치 확인)
        updateFaceTrackingIfNeeded(from: frame, currentTime: currentTime)

        // (현재 시간 - 마지막으로 검사한 시간)이 0.1초보다 작거나 같으면 아래 코드 실행하지 말고 이 프레임 버리기
        guard currentTime - lastHandPoseUpdateTime > 0.1 else { return }

        // gurad문 무사히 통과했다면 마지막 검사시간을 지금 시간으로 업데이트
        lastHandPoseUpdateTime = currentTime
        // 이 프레임의 이미지 데이터를 AI엔진에게 전달해서 손가락 분석
        handTrackingManager.updateHandPose(from: frame.capturedImage)
    }

    private func updateFaceTrackingIfNeeded(from frame: ARFrame, currentTime: TimeInterval) {
        guard currentTime - lastFaceTrackingUpdateTime > 0.18 else { return }

        lastFaceTrackingUpdateTime = currentTime
        _ = emotionRuntime.updateFaceTracking(
            in: frame.capturedImage,
            orientation: .right
        )
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
}

private enum PlaneVisualAction {
    case add
    case update
}
