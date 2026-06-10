//
//  PlacementManager.swift -> Placement(배치) 담당
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit
import CoreGraphics
import simd
import OSLog

// swiftlint:disable type_body_length
@MainActor
final class PlacementManager {
    private static let bottleDistanceFromCamera: Float = 0.8
    private static let bottleAnchorName = "BottleWorldAnchor"
    private weak var arView: ARView?
    private var sceneAnchors: [AnchorEntity] = []
    private var bottleEntity: Entity?
    private var bottleAnchorEntity: AnchorEntity?
    private var collectedOrbIDs: Set<ObjectIdentifier> = []
    private let magneticSnapDistance: Float = 0.20
    private let snapPullSmoothing: Float = 0.28
    private let snapSuccessDistance: Float = 0.08
    private var selectedOrb: ModelEntity?
    private var selectedOrbAnchor: AnchorEntity?
    private var selectedOrbDepth: Float?
    private var selectedOrbScreenOffset = CGPoint.zero
    private var orbPairs: [(orb: ModelEntity, anchor: AnchorEntity)] = []
    private var invisibleFloorEntity: Entity?
    private var invisibleFloorAnchor: AnchorEntity?
    private(set) var placedOrbs: [OrbData] = []
    private(set) var playAreaCenter: SIMD3<Float>?
    private(set) var floorY: Float?
    var onCollectedCountChanged: ((Int) -> Void)?
    var hasSelectedOrb: Bool {
        selectedOrb != nil
    }

    var hasFloor: Bool {
        invisibleFloorEntity != nil
    }

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func placeOrb(emotion: EmotionType, at position: SIMD3<Float>) {
        guard let arView else { return }

        let orb = OrbEntity.makeOrb(emotion: emotion)
        let orbRadius = OrbEntity.collisionRadius(for: orb)
        let correctedPosition = floorSafeOrbPosition(from: position, orbRadius: orbRadius)
        let anchor = AnchorEntity(world: correctedPosition)

        anchor.addChild(orb)
        arView.scene.addAnchor(anchor)

        sceneAnchors.append(anchor)
        registerMovableOrb(orb, anchor: anchor)
        placedOrbs.append(OrbData(emotion: emotion, position: correctedPosition)) // id 어쩔?
    }

    func placeOrb(event: EmotionOrbEvent) {
        let position = event.speakerMouthCenter
            .flatMap(normalizedScreenPosition)
            .flatMap(horizontalPlanePosition)
            .map { $0 + SIMD3<Float>(0, 0.08, 0) }
        ?? fallbackOrbPosition()

        placeOrb(emotion: event.emotion, at: position)
    }

    func placeBottleInFrontOfCamera() {
        guard let arView,
              let frame = arView.session.currentFrame,
              let floorY
        else { return }

        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let cameraForward = normalize(-SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        ))
        let floorForward = SIMD3<Float>(cameraForward.x, 0, cameraForward.z)
        let forwardLength = length(floorForward)

        guard forwardLength > 0.0001 else { return }

        let horizontalForward = floorForward / forwardLength
        let targetPosition = cameraPosition + horizontalForward * Self.bottleDistanceFromCamera
        let bottlePosition = SIMD3<Float>(targetPosition.x, floorY, targetPosition.z)

        Task {
            let bottle = await BottleEntity.makeBottle()
            bottleEntity = bottle

            let anchor = AnchorEntity(world: bottlePosition)
            anchor.name = Self.bottleAnchorName
            bottleAnchorEntity = anchor

            let bounds = bottle.visualBounds(relativeTo: bottle)
            bottle.position = SIMD3<Float>(0, -bounds.min.y, 0)

            anchor.addChild(bottle)
            arView.scene.addAnchor(anchor)
            sceneAnchors.append(anchor)
        }
    }

    func registerMovableOrb(_ trackedOrb: TrackedOrb) {
        registerMovableOrb(trackedOrb.entity, anchor: trackedOrb.anchor)
    }

    private func registerMovableOrb(_ orb: ModelEntity, anchor: AnchorEntity) {
        guard !orbPairs.contains(where: { $0.orb === orb }) else {
            return
        }

        orbPairs.append((orb, anchor))
    }

    @discardableResult
    func selectOrb(at screenPoint: CGPoint) -> ModelEntity? { // 화면 좌표에 있는 엔티티 찾기
        guard let arView else { return nil }

        let grabScreenDistance: CGFloat = 100

        var nearestPair: (orb: ModelEntity, anchor: AnchorEntity)?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for pair in orbPairs {
            let orb = pair.orb
            guard !collectedOrbIDs.contains(ObjectIdentifier(orb)) else { continue }
            let worldPosition = orb.position(relativeTo: nil)
            guard let orbScreenPoint = arView.project(worldPosition) else { continue }

            let xDistance = screenPoint.x - orbScreenPoint.x
            let yDistance = screenPoint.y - orbScreenPoint.y
            let distance = sqrt(xDistance * xDistance + yDistance * yDistance)

            if distance < nearestDistance {
                nearestDistance = distance
                nearestPair = pair
            }
        }

        guard let nearestPair, nearestDistance <= grabScreenDistance else {
            Logger.placement.debug("선택 가능한 구슬 없음, 가장 가까운 거리: \(nearestDistance)")
            return nil
        }

        selectedOrb = nearestPair.orb
        selectedOrbAnchor = nearestPair.anchor

        if let orbScreenPoint = arView.project(nearestPair.orb.position(relativeTo: nil)) {
            selectedOrbScreenOffset = CGPoint(
                x: orbScreenPoint.x - screenPoint.x,
                y: orbScreenPoint.y - screenPoint.y
            )
        }

        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let cameraPosition = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )

            let cameraForward = normalize(-SIMD3<Float>(
                cameraTransform.columns.2.x,
                cameraTransform.columns.2.y,
                cameraTransform.columns.2.z
            ))

            let orbPosition = nearestPair.orb.position(relativeTo: nil)

            selectedOrbDepth = max(simd_dot(orbPosition - cameraPosition, cameraForward), 0.1)
        }

        if selectedOrbDepth == nil {
            selectedOrbDepth = 0.5
        }

        Logger.placement.debug("가장 가까운 구슬 선택됨: \(nearestPair.orb.name)")
        return nearestPair.orb
    }

    func orbTouchFeedbackIntensity(at screenPoint: CGPoint) -> Float? {
        guard let arView else { return nil }

        var strongestIntensity: Float?

        for pair in orbPairs {
            let orb = pair.orb
            guard !collectedOrbIDs.contains(ObjectIdentifier(orb)) else { continue }

            let worldPosition = orb.position(relativeTo: nil)
            guard let orbScreenPoint = arView.project(worldPosition) else { continue }

            let screenRadius = projectedScreenRadius(for: orb, at: worldPosition)
            let outerRadius = screenRadius * 2.2
            let distance = hypot(screenPoint.x - orbScreenPoint.x, screenPoint.y - orbScreenPoint.y)

            guard distance <= outerRadius else { continue }

            let intensity = touchIntensity(
                distance: distance,
                screenRadius: screenRadius,
                outerRadius: outerRadius
            )
            strongestIntensity = max(strongestIntensity ?? 0, intensity)
        }

        return strongestIntensity
    }

    func moveSelectedOrb(to screenPoint: CGPoint) {
        guard let selectedOrb else { return }
        let targetScreenPoint = CGPoint(
            x: screenPoint.x + selectedOrbScreenOffset.x,
            y: screenPoint.y + selectedOrbScreenOffset.y
        )
        guard let worldPosition = depthPlanePosition(from: targetScreenPoint) else {
            Logger.placement.debug("구슬 이동 실패")
            return
        }

        let currentPosition = selectedOrb.position(relativeTo: nil)
        let smoothing: Float = 0.25

        let smoothedPosition = simd_mix(
            currentPosition,
            worldPosition,
            SIMD3<Float>(repeating: smoothing)
        )

        let assistedPosition = magnetizedPosition(from: smoothedPosition)
        selectedOrb.setPosition(assistedPosition, relativeTo: nil)
        snapSelectedOrbIfNeeded()
    }
    @discardableResult
    func releaseSelectedOrb() -> ModelEntity? {
        guard hasSelectedOrb else { return nil }
        snapSelectedOrbIfNeeded()
        guard hasSelectedOrb else { return nil }

        let releasedOrb = selectedOrb
        selectedOrb = nil
        selectedOrbAnchor = nil
        selectedOrbDepth = nil
        selectedOrbScreenOffset = .zero
        Logger.placement.debug("구슬 놓기 완료")
        return releasedOrb
    }
    func screenPoint(fromNormalizedPoint point: CGPoint) -> CGPoint? { // 화면 좌표 시스템 -> iOS 화면의 실제 픽셀 좌표(ScreenPoint)로 변환
        guard let arView else { return nil }
        return CGPoint(
            x: point.x * arView.bounds.width,
            y: (1 - point.y) * arView.bounds.height // Vision 좌표계와 UIKit 화면 좌표계의 y축 방향 다름
        )
    }
    private func normalizedScreenPosition(_ point: CGPoint) -> CGPoint? {
        screenPoint(fromNormalizedPoint: point)
    }

    private func floorSafeOrbPosition(from position: SIMD3<Float>, orbRadius: Float) -> SIMD3<Float> {
        guard let floorY else {
            return position
        }

        return SIMD3<Float>(
            position.x,
            max(position.y, floorY + orbRadius),
            position.z
        )
    }

    private func fallbackOrbPosition() -> SIMD3<Float> {
        guard
            let arView,
            let frame = arView.session.currentFrame
        else {
            return SIMD3<Float>(0, 0, -0.5)
        }

        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let cameraForward = normalize(-SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        ))

        return cameraPosition + cameraForward * 0.7
    }
    func clearScene() {
        for anchor in sceneAnchors {
            anchor.removeFromParent()
        }

        sceneAnchors.removeAll()
        orbPairs.removeAll()
        placedOrbs.removeAll()
        collectedOrbIDs.removeAll()
        bottleEntity = nil
        bottleAnchorEntity = nil
        invisibleFloorEntity = nil
        invisibleFloorAnchor = nil
        playAreaCenter = nil
        floorY = nil
    }

    func horizontalPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? { // 2D -> 3D

        guard let arView else { return nil }
        return PlaneRaycaster.horizontalPlanePosition(from: screenPoint, in: arView)
    }

    func createInvisiblePhysicsFloor(
        at position: SIMD3<Float>,
        shouldUpdateHeight: Bool = true
    ) {
        guard let arView else {
            return
        }

        let floorPosition = stableFloorPosition(
            from: position,
            shouldUpdateHeight: shouldUpdateHeight
        )

        if let invisibleFloorAnchor {
            invisibleFloorAnchor.setPosition(floorPosition, relativeTo: nil)
            playAreaCenter = floorPosition
            floorY = floorPosition.y
            return
        }

        let floorSize = SIMD3<Float>(12.0, 0.04, 12.0)
        let collisionShape = ShapeResource.generateBox(size: floorSize)
        let floorEntity = Entity()
        floorEntity.name = "InvisiblePhysicsFloor"
        floorEntity.position.y = -(floorSize.y / 2)
        OrbPhysicsSettings.applyStaticBody(to: floorEntity, shape: collisionShape)

        let anchor = AnchorEntity(world: floorPosition)
        anchor.name = "InvisibleFloorAnchor"
        anchor.addChild(floorEntity)

        arView.scene.addAnchor(anchor)
        sceneAnchors.append(anchor)
        invisibleFloorEntity = floorEntity
        invisibleFloorAnchor = anchor
        playAreaCenter = floorPosition
        floorY = floorPosition.y
    }

    private func stableFloorPosition(
        from position: SIMD3<Float>,
        shouldUpdateHeight: Bool
    ) -> SIMD3<Float> {
        guard let floorY, !shouldUpdateHeight else { return position }

        return SIMD3<Float>(position.x, floorY, position.z)
    }

    private func addToScene(_ entity: Entity, at position: SIMD3<Float>) {
        guard let arView else { return }

        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        sceneAnchors.append(anchor)
    }

    private func depthPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let arView else { return nil }
        guard let selectedOrbDepth else { return nil }
        guard let ray = arView.ray(through: screenPoint) else { return nil }
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return nil }

        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let cameraForword = normalize(-SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        ))

        let planePoint = cameraPosition + cameraForword * selectedOrbDepth
        let planeNormal = cameraForword

        let rayOrigin = ray.origin
        let rayDirection = normalize(ray.direction)

        let denominator = simd_dot(rayDirection, planeNormal)
        guard abs(denominator) > 0.0001 else { return nil }

        let intersectionDistance = simd_dot(planePoint - rayOrigin, planeNormal) / denominator

        guard intersectionDistance >= 0 else { return nil }

        return rayOrigin + rayDirection * intersectionDistance
    }
    private func projectedScreenRadius(for orb: ModelEntity, at worldPosition: SIMD3<Float>) -> CGFloat {
        guard let arView,
              let cameraTransform = arView.session.currentFrame?.camera.transform,
              let centerPoint = arView.project(worldPosition)
        else {
            return 42
        }

        let radius = OrbEntity.collisionRadius(for: orb)
        let cameraRight = normalize(SIMD3<Float>(
            cameraTransform.columns.0.x,
            cameraTransform.columns.0.y,
            cameraTransform.columns.0.z
        ))
        let edgePosition = worldPosition + cameraRight * radius

        guard let edgePoint = arView.project(edgePosition) else {
            return 42
        }

        return max(hypot(edgePoint.x - centerPoint.x, edgePoint.y - centerPoint.y), 36)
    }

    private func touchIntensity(distance: CGFloat, screenRadius: CGFloat, outerRadius: CGFloat) -> Float {
        if distance > screenRadius {
            let shellDepth = 1 - ((distance - screenRadius) / max(outerRadius - screenRadius, 1))
            return 0.20 + Float(shellDepth) * 0.22
        }

        let normalizedDepth = 1 - min(max(distance / max(screenRadius, 1), 0), 1)
        return 0.42 + Float(normalizedDepth) * 0.56
    }
    private func bottleMouthPosition() -> SIMD3<Float>? {
        guard let bottleAnchorEntity else { return nil }
        return bottleAnchorEntity.position(relativeTo: nil) + SIMD3<Float>(0, 0.22, 0)
    }
    private func magnetizedPosition(from proposedPosition: SIMD3<Float>) -> SIMD3<Float> {
        guard let mouthPosition = bottleMouthPosition() else { return proposedPosition }

        let distance = simd_distance(proposedPosition, mouthPosition)

        guard distance <= magneticSnapDistance else { return proposedPosition }

        let normalizedCloseness = 1.0 - min(max(distance / magneticSnapDistance, 0), 1)
        let pull = snapPullSmoothing + normalizedCloseness * 0.22

        return simd_mix(
            proposedPosition,
            mouthPosition,
            SIMD3<Float>(repeating: pull)
        )
    }
    private func bottleInsideLocalPosition() -> SIMD3<Float> {
        let slots: [SIMD3<Float>] = [
            [-0.105, 0.125, 0.060],
            [0.105, 0.130, 0.055],
            [0.000, 0.135, -0.085],
            [-0.010, 0.140, 0.000],

            [-0.080, 0.195, -0.035],
            [0.082, 0.200, 0.025],
            [0.000, 0.205, 0.090],
            [0.015, 0.210, -0.065],

            [-0.055, 0.265, 0.050],
            [0.060, 0.270, -0.045],
            [0.000, 0.285, 0.000]
        ]

        let slotIndex = min(max(collectedOrbIDs.count - 1, 0), slots.count - 1)
        return slots[slotIndex]
    }

    private func isOrbInsideBottleCaptureArea(_ orb: ModelEntity) -> Bool {
        guard let bottleAnchorEntity else { return false }

        let localPosition = orb.position(relativeTo: bottleAnchorEntity)

        let horizontalDistance = sqrt(
            localPosition.x * localPosition.x +
            localPosition.z * localPosition.z
        )

        let isInsideMouthRadius = horizontalDistance <= 0.040
        let isNearMouthHeight = localPosition.y >= 0.17 && localPosition.y <= 0.32

        return isInsideMouthRadius && isNearMouthHeight
    }

    private func snapSelectedOrbIfNeeded() {
        guard let selectedOrb,
              let mouthPosition = bottleMouthPosition()
        else { return }

        let orbID = ObjectIdentifier(selectedOrb)

        guard !collectedOrbIDs.contains(orbID) else { return }

        let orbPosition = selectedOrb.position(relativeTo: nil)
        let distance = simd_distance(orbPosition, mouthPosition)

        let isCloseToMouth = distance <= snapSuccessDistance
        let isInsideCaptureArea = isOrbInsideBottleCaptureArea(selectedOrb)

        guard isCloseToMouth || isInsideCaptureArea else { return }

        collectedOrbIDs.insert(orbID)
        onCollectedCountChanged?(collectedOrbIDs.count)

        if var body = selectedOrb.components[PhysicsBodyComponent.self] {
            body.mode = .kinematic
            selectedOrb.components.set(body)
        }

        selectedOrb.components.set(
            PhysicsMotionComponent(
                linearVelocity: .zero,
                angularVelocity: .zero
            )
        )

        if let bottleAnchorEntity {
            selectedOrb.setParent(bottleAnchorEntity, preservingWorldTransform: false)
            selectedOrb.position = bottleInsideLocalPosition()
            selectedOrb.scale = SIMD3<Float>(repeating: 0.48)
        }

        self.selectedOrb = nil
        selectedOrbAnchor = nil
        selectedOrbDepth = nil
        selectedOrbScreenOffset = .zero
        Logger.placement.debug("구슬 수집 완료")
    }
}
// swiftlint:enable type_body_length
