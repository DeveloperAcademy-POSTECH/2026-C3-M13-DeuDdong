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

@MainActor
final class PlacementManager {
    private weak var arView: ARView?
    private var sceneAnchors: [AnchorEntity] = []
    private(set) var placedOrbs: [OrbData] = []
    
    func attach(to arView: ARView) {
        self.arView = arView
    }
    
    func placeOrb(emotion: EmotionType, at position: SIMD3<Float>) {
        let orb = OrbEntity.makeOrb(emotion: emotion)
        addToScene(orb, at: position)
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
    
    func placeBottle(at position: SIMD3<Float>) {
        let bottle = BottleEntity.makeBottle()
        addToScene(bottle, at: position)
    }
    
    func clearScene() {
        for anchor in sceneAnchors {
            anchor.removeFromParent()
        }
        
        sceneAnchors.removeAll()
        placedOrbs.removeAll()
    }
    
    func horizontalPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let arView else { return nil }
        return PlaneRaycaster.horizontalPlanePosition(from: screenPoint, in: arView)
    }
    
    func placeDemoObjects(on planeAnchor: ARPlaneAnchor) {
        let center = planeAnchor.worldCenter
        
        placeBottle(at: center + SIMD3<Float>(0, 0.1, 0))
        placeOrb(emotion: .praise, at: center + SIMD3<Float>(0.1, 0.05, 0.05))
        placeOrb(emotion: .encouragement, at: center + SIMD3<Float>(0.5, 0.03, 0.09))
        placeOrb(emotion: .affection, at: center + SIMD3<Float>(0.11, 0.03, 0.07))
        placeOrb(emotion: .gratitude, at: center + SIMD3<Float>(0.12, 0.04, 0.08))
        placeOrb(emotion: .empathy, at: center + SIMD3<Float>(0.3, 0.09, 0.1))
    }
    
    private func addToScene(_ entity: Entity, at position: SIMD3<Float>) {
        guard let arView else { return }
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        sceneAnchors.append(anchor)
    }

    private func normalizedScreenPosition(_ point: CGPoint) -> CGPoint? {
        guard let arView else { return nil }

        return CGPoint(
            x: point.x * arView.bounds.width,
            y: point.y * arView.bounds.height
        )
    }

    private func fallbackOrbPosition() -> SIMD3<Float> {
        guard let arView else { return SIMD3<Float>(0, 0, -0.5) }

        let matrix = arView.cameraTransform.matrix
        let cameraPosition = SIMD3<Float>(
            matrix.columns.3.x,
            matrix.columns.3.y,
            matrix.columns.3.z
        )
        let forward = -SIMD3<Float>(
            matrix.columns.2.x,
            matrix.columns.2.y,
            matrix.columns.2.z
        )

        return cameraPosition + forward * 0.55 + SIMD3<Float>(0, -0.12, 0)
    }
}
