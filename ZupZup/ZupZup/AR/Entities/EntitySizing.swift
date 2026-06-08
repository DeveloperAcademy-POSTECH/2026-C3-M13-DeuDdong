//
//  EntitySizing.swift
//  ZupZup
//

import RealityKit

@MainActor
enum EntitySizing {
    enum Axis {
        case width
        case height
        case depth
    }

    /// 엔티티의 바운딩 박스를 측정해, 지정한 축의 실제 크기가 target(미터)이 되도록 비율을 유지한 채 스케일을 적용한다.
    static func scale(_ entity: Entity, toFit axis: Axis, target: Float) {
        let extents = entity.visualBounds(relativeTo: nil).extents

        let current: Float
        switch axis {
        case .width: current = extents.x
        case .height: current = extents.y
        case .depth: current = extents.z
        }

        guard current > 0 else { return }
        entity.scale = SIMD3<Float>(repeating: target / current)
    }
}
