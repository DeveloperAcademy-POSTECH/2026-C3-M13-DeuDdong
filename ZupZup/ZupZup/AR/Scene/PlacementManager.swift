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

@MainActor
final class PlacementManager {
    private static let bottleCameraOffset = SIMD3<Float>(0, -0.1, -0.5)

    private weak var arView: ARView?
    private var sceneAnchors: [AnchorEntity] = []
    private var selectedOrb: ModelEntity?
    private var selectedOrbAnchor: AnchorEntity?
    private var selectedOrbDepth: Float?
    private var selectedOrbScreenOffset = CGPoint.zero
    private var orbPairs: [(orb: ModelEntity, anchor: AnchorEntity)] = []
    private var invisibleFloorEntity: Entity?
    private(set) var placedOrbs: [OrbData] = []
    private(set) var playAreaCenter: SIMD3<Float>?
    private(set) var floorY: Float?

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

        // let orb = OrbEntity.makeOrb(emotion: emotion) // 구슬 객체 생성
        let orb = OrbEntity.makeDebugOrb(emotion: emotion) // 디버그용 임시 구슬
        let anchor = AnchorEntity(world: position)

        anchor.addChild(orb)
        arView.scene.addAnchor(anchor)

        sceneAnchors.append(anchor)
        orbPairs.append((orb, anchor))
        placedOrbs.append(OrbData(emotion: emotion, position: position)) // id 어쩔?
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
        guard let arView else { return }

        Task {
            let bottle = await BottleEntity.makeBottle()

            let anchor = AnchorEntity(.camera)
            anchor.name = "BottleCameraAnchor"
            bottle.position = Self.bottleCameraOffset

            anchor.addChild(bottle)
            arView.scene.addAnchor(anchor)
            sceneAnchors.append(anchor)
        }
    }

    func selectOrb(at screenPoint: CGPoint) { // 화면 좌표에 있는 엔티티 찾기
        guard let arView else { return }

        let grabScreenDistance: CGFloat = 138

        var nearestPair: (orb: ModelEntity, anchor: AnchorEntity)?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for pair in orbPairs {
            let worldPosition = pair.orb.position(relativeTo: nil)

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
            return
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

        selectedOrb.setPosition(smoothedPosition, relativeTo: nil)
    }
    func releaseSelectedOrb() {
        guard hasSelectedOrb else { return }
        selectedOrb = nil
        selectedOrbAnchor = nil
        selectedOrbDepth = nil
        selectedOrbScreenOffset = .zero
        Logger.placement.debug("구슬 놓기 완료")
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
        invisibleFloorEntity = nil
        playAreaCenter = nil
        floorY = nil
    }

    func horizontalPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? { // 2D -> 3D

        guard let arView else { return nil }
        return PlaneRaycaster.horizontalPlanePosition(from: screenPoint, in: arView)
    }

    func placeDemoObjects(on planeAnchor: ARPlaneAnchor) {
        guard let center = cameraFrontFloorPosition(floorY: planeAnchor.worldCenter.y) else {
            return
        }

        placeBottleInFrontOfCamera()

        placeOrb(emotion: .praise, at: center + SIMD3<Float>(-0.18, 0.025, 0.02))
        placeOrb(emotion: .encouragement, at: center + SIMD3<Float>(-0.11, 0.025, 0.08))
        placeOrb(emotion: .affection, at: center + SIMD3<Float>(0.12, 0.025, 0.07))
        placeOrb(emotion: .gratitude, at: center + SIMD3<Float>(0.18, 0.025, -0.02))
        placeOrb(emotion: .empathy, at: center + SIMD3<Float>(-0.05, 0.025, 0.14))
    }

    private func cameraFrontFloorPosition(floorY: Float) -> SIMD3<Float>? {
        guard let arView, let frame = arView.session.currentFrame else { return nil }

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

        let floorForward = SIMD3<Float>(
            cameraForward.x,
            0,
            cameraForward.z
        )

        let forwardLength = length(floorForward)

        guard forwardLength > 0.0001 else {
            return nil
        }

        let horizontalForward = floorForward / forwardLength
        let target = cameraPosition + horizontalForward * 0.7

        return SIMD3<Float>(
            target.x,
            floorY,
            target.z
        )
    }

    func createInvisiblePhysicsFloor(at position: SIMD3<Float>) {
        guard let arView, invisibleFloorEntity == nil else {
            return
        }

        let floorSize = SIMD3<Float>(12.0, 0.04, 12.0)
        let collisionShape = ShapeResource.generateBox(size: floorSize)
        let floorEntity = Entity()
        floorEntity.name = "InvisiblePhysicsFloor"
        OrbPhysicsSettings.applyStaticBody(to: floorEntity, shape: collisionShape)

        let anchor = AnchorEntity(world: position)
        anchor.name = "InvisibleFloorAnchor"
        anchor.addChild(floorEntity)

        arView.scene.addAnchor(anchor)
        sceneAnchors.append(anchor)
        invisibleFloorEntity = floorEntity
        playAreaCenter = position
        floorY = position.y
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
}
