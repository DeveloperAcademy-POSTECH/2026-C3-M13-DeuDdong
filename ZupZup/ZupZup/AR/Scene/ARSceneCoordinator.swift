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
    private var planeVisualizer: PlaneVisualizer?
    private var onPlaneStateChange: (ARState) -> Void
    private var hasPlacedDemoObjects = false
    
    init(
        sessionManager: ARSessionManager,
        placementManager: PlacementManager,
        onPlaneStateChange: @escaping (ARState) -> Void
    ) {
        self.sessionManager = sessionManager
        self.placementManager = placementManager
        self.onPlaneStateChange = onPlaneStateChange
    }
        // ARSceneCoordinator는 두뇌같은 역할이죠. 그치만 멍청한 친구 같아요. 왜 자꾸 말을 안 듣니?
    func install(on arView: ARView) {
        sessionManager.attach(to: arView)
        placementManager.attach(to: arView)
        planeVisualizer = PlaneVisualizer(arView: arView)
        arView.session.delegate = self
        sessionManager.startSession()
    }
    
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
