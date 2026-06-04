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
    private var orbEntities: [ModelEntity] = [] //만들어진 구슬 엔티티 배열(실제로 화면에 있는 구슬 객체)
    private var selectedOrb: ModelEntity?
    private(set) var placedOrbs: [OrbData] = [] //구슬의 종류와 좌표값만 따로 저장하는 데이터 모델
    
    func attach(to arView: ARView) {
        self.arView = arView
    }
    
    func placeOrb(emotion: EmotionType, at position: SIMD3<Float>) {
        let orb = OrbEntity.makeOrb(emotion: emotion) //구슬 객체 생성
        orbEntities.append(orb) //관리 배열에 추가
        addToScene(orb, at: position)
        placedOrbs.append(OrbData(emotion: emotion, position: position)) // id 어쩔?
    }
    
    func placeBottle(at position: SIMD3<Float>) {
        let bottle = BottleEntity.makeBottle()
        addToScene(bottle, at: position)
    }
    
    func selectOrb(at screenPoint: CGPoint) { //화면 좌표에 있는 엔티티 찾기
        guard let arView else { return }
        
        guard let hitEntity = arView.entity(at: screenPoint) else {
            selectedOrb = nil
            return
        }
        
        if let orb = orbEntities.first(where: { $0 == hitEntity }) {
            selectedOrb = orb
        } else {
            selectedOrb = nil
        }
    }
    
    func screenPoint(fromNormalizedPoint point: CGPoint) -> CGPoint? { //화면 좌표 시스템 -> iOS 화면의 실제 픽셀 좌표(ScreenPoint)로 변환
        guard let arView else { return nil }
        
        return CGPoint(
            x: point.x * arView.bounds.width,
            y: (1 - point.y) * arView.bounds.height //Vision 좌표계와 UIKit 화면 좌표계의 y축 방향 다름
        )
    }
    
    func clearScene() {
        for anchor in sceneAnchors {
            anchor.removeFromParent()
        }
        
        sceneAnchors.removeAll()
        orbEntities.removeAll()
        placedOrbs.removeAll()
    }
    
    func horizontalPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? { //2D -> 3D
        guard let arView else { return nil }
        return PlaneRaycaster.horizontalPlanePosition(from: screenPoint, in: arView)
    }
    
    func placeDemoObjects(on planeAnchor: ARPlaneAnchor) {
        let center = planeAnchor.worldCenter //인식된 평면의 중심점
        
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
}
