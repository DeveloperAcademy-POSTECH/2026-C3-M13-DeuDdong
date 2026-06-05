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
    private let logger = Logger(subsystem: "ZupZup", category: "Placement")
    
    private weak var arView: ARView?
    private var sceneAnchors: [AnchorEntity] = []
    private var orbEntities: [ModelEntity] = [] //만들어진 구슬 엔티티 배열(실제로 화면에 있는 구슬 객체)
    private var selectedOrb: ModelEntity?
    private var selectedOrbAnchor: AnchorEntity?
    
    private(set) var placedOrbs: [OrbData] = [] //구슬의 종류와 좌표값만 따로 저장하는 데이터 모델
    private var orbPairs: [(orb: ModelEntity, anchor: AnchorEntity)] = [] // 모델 엔티티와 앵커 앤티티 같이 저장
    
    var hasSelectedOrb: Bool {
        selectedOrb != nil
    }
    
    func attach(to arView: ARView) {
        self.arView = arView
    }
    
    func placeOrb(emotion: EmotionType, at position: SIMD3<Float>) {
        guard let arView else { return }
        
        // let orb = OrbEntity.makeOrb(emotion: emotion) //구슬 객체 생성
        let orb = OrbEntity.makeDebugOrb(emotion: emotion) //디버그용 임시 구슬
        let anchor = AnchorEntity(world: position)
        
        anchor.addChild(orb)
        arView.scene.addAnchor(anchor)
        
        sceneAnchors.append(anchor)
        orbEntities.append(orb) //관리 배열에 추가
        orbPairs.append((orb, anchor))
        placedOrbs.append(OrbData(emotion: emotion, position: position)) // id 어쩔?
    }
    
    func placeBottle(at position: SIMD3<Float>) {
        let bottle = BottleEntity.makeBottle()
        addToScene(bottle, at: position)
    }
    
    func selectOrb(at screenPoint: CGPoint) { //화면 좌표에 있는 엔티티 찾기
        guard let arView else { return }
        
        let selectionThreshold: CGFloat = 70
        
        var nearestPair: (orb: ModelEntity, anchor: AnchorEntity)?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude
        
        for pair in orbPairs {
            let worldPosition = pair.anchor.position(relativeTo: nil)
            
            guard let orbScreenPoint = arView.project(worldPosition) else { continue }
            
            
            
            let dx = screenPoint.x - orbScreenPoint.x
            let dy = screenPoint.y - orbScreenPoint.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < nearestDistance {
                nearestDistance = distance
                nearestPair = pair
            }
        }
        
        guard let nearestPair, nearestDistance <= selectionThreshold else {
            selectedOrb = nil
            selectedOrbAnchor = nil
            logger.debug("선택 가능한 구슬 없음, 가장 가까운 거리: \(nearestDistance)")
            return
        }
        
        selectedOrb = nearestPair.orb
        selectedOrbAnchor = nearestPair.anchor
        logger.debug("가장 가까운 구슬 선택됨: \(nearestPair.orb.name)")
    }
    
    func moveSelectedOrb(to screenPoint: CGPoint) {
        guard let selectedOrbAnchor else { return }
        guard let worldPosition = horizontalPlanePosition(from: screenPoint) else {
            logger.debug("구슬 이동 실패: 바닥 좌표를 찾지 못함 x: \(screenPoint.x), y: \(screenPoint.y)")
            return }
        
        selectedOrbAnchor.position = worldPosition
        logger.debug("구슬 이동됨 x: \(worldPosition.x), y: \(worldPosition.y), z: \(worldPosition.z)")
    }
    
    func releaseSelectedOrb() {
        guard hasSelectedOrb else { return }
        
        selectedOrb = nil
        selectedOrbAnchor = nil
        logger.debug("구슬 놓기 완료")
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
        orbPairs.removeAll()
        placedOrbs.removeAll()
    }
    
    func horizontalPlanePosition(from screenPoint: CGPoint) -> SIMD3<Float>? { //2D -> 3D
        guard let arView else { return nil }
        return PlaneRaycaster.horizontalPlanePosition(from: screenPoint, in: arView)
    }
    
    func placeDemoObjects(on planeAnchor: ARPlaneAnchor) {
        let center = planeAnchor.worldCenter //인식된 평면의 중심점
        
        placeBottle(at: center + SIMD3<Float>(0, 0.1, 0))
        placeOrb(emotion: .praise, at: center + SIMD3<Float>(-0.25, 0.06, 0.0))
        placeOrb(emotion: .encouragement, at: center + SIMD3<Float>(0.0, 0.06, 0.0))
        placeOrb(emotion: .affection, at: center + SIMD3<Float>(0.25, 0.06, 0.0))
        placeOrb(emotion: .gratitude, at: center + SIMD3<Float>(-0.12, 0.06, 0.25))
        placeOrb(emotion: .empathy, at: center + SIMD3<Float>(0.12, 0.06, 0.25))
    }
    
    private func addToScene(_ entity: Entity, at position: SIMD3<Float>) {
        guard let arView else { return }
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        sceneAnchors.append(anchor)
    }
}
