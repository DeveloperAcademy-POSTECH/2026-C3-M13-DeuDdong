//
//  TrackedOrb.swift
//  ZupZup
//
// 생성된 구슬의 anchor, entity, state 추적하는 모델 파일

import Foundation
import RealityKit

enum OrbPhysicsState: String {
    case waiting
    case falling
    case bounced
    case settled
}

final class TrackedOrb {
    let anchor: AnchorEntity
    let entity: ModelEntity
    let radius: Float
    var state: OrbPhysicsState = .waiting
    var hasBounced = false
    var hasManualInteraction = false
    var touchedFloorTime: CFTimeInterval?
    var settledTime: CFTimeInterval?

    init(anchor: AnchorEntity, entity: ModelEntity, radius: Float) {
        self.anchor = anchor
        self.entity = entity
        self.radius = radius
    }
}
