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
    private var lastFaceTrackingUpdateTime: TimeInterval = 0
    private let handTrackingManager = HandTrackingManager.shared
    private let orbSpawnManager = OrbSpawnManager()
    private let orbPhysicsController = OrbPhysicsController()
    private var planeVisualizer: PlaneVisualizer?
    private var onPlaneStateChange: (ARState) -> Void
    private weak var arView: ARView?
    private var hasPlacedDemoObjects = false
    private var lastHandPoseUpdateTime: TimeInterval = 0
    private var wasPinching = false
    private var lastPinchSeenTime: TimeInterval = 0
    private let pinchLostGraceDuration: TimeInterval = 0.3
    private var isCollecting = false
    private var horizontalPlaneAnchors: [UUID: ARPlaneAnchor] = [:]
    private var isHandPoseRequestInFlight = false
    private let handPoseQueue = DispatchQueue(label: "com.zupzup.handPose")
    private var lastOrbPhysicsUpdateTime: CFTimeInterval?
    private var fallbackOrbFloorY: Float?

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

    func triggerDebugOrbPlacement(count: Int = 1) {
        let safeCount = max(1, count)
        for _ in 0..<safeCount {
            createPhysicsOrb(for: nil)
        }
    }

    func toggleGridVisibility() -> Bool {
        planeVisualizer?.toggleVisible() ?? true
    }
    #endif

    func updatePlaneStateHandler(_ handler: @escaping (ARState) -> Void) {
        onPlaneStateChange = handler
    }

    func setPlaneVisualizationVisible(_ isVisible: Bool) {
        planeVisualizer?.setVisible(isVisible)
    }
    
    func setCollectionMode(_ isCollecting: Bool) {
        self.isCollecting = isCollecting
    }

    func placeOrb(event: EmotionOrbEvent) {
        createPhysicsOrb(for: event.emotion, mouthNormalizedPoint: event.speakerMouthCenter)
    }

    func resetScene() {
        hasPlacedDemoObjects = false
        lastOrbPhysicsUpdateTime = nil
        fallbackOrbFloorY = nil
        horizontalPlaneAnchors.removeAll()
        planeVisualizer?.removeAll()
        orbPhysicsController.removeAll(from: arView)
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

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTime = Date().timeIntervalSince1970
        updatePhysicsOrbsIfNeeded(now: currentTime)
        updateFaceTrackingIfNeeded(from: frame, currentTime: currentTime)
        updateHandTrackingIfNeeded(from: frame, currentTime: currentTime)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            planeVisualizer?.remove(anchor.identifier)
            horizontalPlaneAnchors.removeValue(forKey: anchor.identifier)
        }
    }
    private func updateFaceTrackingIfNeeded(from frame: ARFrame, currentTime: TimeInterval) {
        guard currentTime - lastFaceTrackingUpdateTime > 0.18 else { return }

        lastFaceTrackingUpdateTime = currentTime

        _ = emotionRuntime.updateFaceTracking(
            in: frame.capturedImage,
            orientation: .right
        )
    }
    private func updateHandTrackingIfNeeded(from frame: ARFrame, currentTime: TimeInterval) {
        guard currentTime - lastHandPoseUpdateTime > 0.1,
              !isHandPoseRequestInFlight
        else {
            return
        }

        lastHandPoseUpdateTime = currentTime
        isHandPoseRequestInFlight = true

        let pixelBuffer = frame.capturedImage

        handPoseQueue.async { [weak self] in
            let result = HandTrackingManager.detectHandPose(from: pixelBuffer)

            Task { @MainActor [weak self] in
                guard let self else { return }

                defer {
                    self.isHandPoseRequestInFlight = false
                }

                HandTrackingManager.shared.apply(result)
                self.handleHandGesture()
            }
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
        updateKnownHorizontalPlanes(with: anchors)

        guard let horizontalPlane = largestHorizontalPlane() else {
            return
        }

        onPlaneStateChange(.ready)
        placementManager.createInvisiblePhysicsFloor(
            at: horizontalPlane.worldCenter,
            shouldUpdateHeight: !hasPlacedDemoObjects && !orbPhysicsController.hasOrbs
        )

        guard !hasPlacedDemoObjects else { return }
        hasPlacedDemoObjects = true
    }

    private func updateKnownHorizontalPlanes(with anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  planeAnchor.alignment == .horizontal else {
                continue
            }

            horizontalPlaneAnchors[planeAnchor.identifier] = planeAnchor
        }
    }

    private func largestHorizontalPlane() -> ARPlaneAnchor? {
        horizontalPlaneAnchors.values.max {
            planeArea($0) < planeArea($1)
        }
    }

    private func planeArea(_ planeAnchor: ARPlaneAnchor) -> Float {
        let extent = planeAnchor.planeExtent
        return extent.width * extent.height
    }

    private func handleHandGesture() {
        guard isCollecting else {
            releaseIfNeeded()
            return
        }
        
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
                placementManager.selectOrb(at: screenPoint, from: orbPhysicsController.trackedOrbs)
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
    private func createPhysicsOrb(for emotion: EmotionType?, mouthNormalizedPoint: CGPoint? = nil) {
        guard let arView,
              let floorY = placementManager.floorY ?? fallbackFloorY(in: arView),
              let trackedOrb = orbSpawnManager.createOrb(
                in: arView,
                floorY: floorY,
                emotion: emotion,
                mouthNormalizedPoint: mouthNormalizedPoint
              ) else {
            return
        }

        fallbackOrbFloorY = floorY
        orbPhysicsController.addOrb(trackedOrb)
    }

    private func updatePhysicsOrbsIfNeeded(now: CFTimeInterval) {
        guard orbPhysicsController.hasOrbs else {
            lastOrbPhysicsUpdateTime = nil
            return
        }

        let deltaTime = Float(min(max(now - (lastOrbPhysicsUpdateTime ?? now), 0), 1.0 / 20.0))
        lastOrbPhysicsUpdateTime = now
        let floorY = placementManager.floorY ?? fallbackOrbFloorY ?? arView.flatMap(fallbackFloorY)
        orbPhysicsController.updateOrbs(
            floorY: floorY,
            deltaTime: deltaTime,
            now: now,
            playAreaCenter: placementManager.playAreaCenter
        )
    }

    private func fallbackFloorY(in arView: ARView) -> Float? {
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
            return nil
        }

        return cameraTransform.columns.3.y - 0.65
    }
}

private enum PlaneVisualAction {
    case add
    case update
}
