//
//  BottleEntity.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit
import UIKit

enum BottleEntity {
    static func makeBottle() -> ModelEntity {
        let size = SIMD3<Float>(0.2, 0.2, 0.2)
        let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.02)
        let material = SimpleMaterial(
            color: UIColor.systemGreen.withAlphaComponent(0.22),
            roughness: 0.2,
            isMetallic: false
        )
        let bottle = ModelEntity(mesh: mesh, materials: [material])
        let shape = ShapeResource.generateBox(size: size)

        bottle.name = "BottlePlaceholder"
        PhysicsSetup.applyStaticBody(to: bottle, shape: shape)
        return bottle
    }
}

