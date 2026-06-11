//
//  BottleEntity.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit

@MainActor
enum BottleEntity {
    private static let assetName = "Balls/Bottle"
    private static let targetWidth: Float = 0.33

    static func makeBottle() async -> Entity {
        guard let loaded = await EntityLoader.load(named: assetName) else {
            fatalError("Failed to load \(assetName)")
        }

        EntitySizing.scale(loaded, toFit: .width, target: targetWidth)

        return loaded
    }
}
