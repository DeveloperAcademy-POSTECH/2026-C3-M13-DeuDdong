//
//  OrbData.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import Foundation
import simd

struct OrbData: Identifiable, Equatable {
    let id: UUID
    let emotion: EmotionType
    let position: SIMD3<Float>

    init(id: UUID = UUID(), emotion: EmotionType, position: SIMD3<Float>) {
        self.id = id
        self.emotion = emotion
        self.position = position
    }
}
