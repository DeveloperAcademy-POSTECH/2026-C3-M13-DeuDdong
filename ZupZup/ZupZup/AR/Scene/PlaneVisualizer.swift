//
//  PlaneVisualizer.swift -> ARKit으로 감지한 바닥에 그리드 보여줌
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit
internal import UIKit

final class PlaneVisualizer {
    private var anchors: [UUID: AnchorEntity] = [:]
    private var meshes: [UUID: ModelEntity] = [:]
    private weak var arView: ARView?
    private var isVisible = true

    init(arView: ARView) {
        self.arView = arView
    }

    func add(_ planeAnchor: ARPlaneAnchor) {
        guard let arView else { return }

        let anchorEntity = AnchorEntity(anchor: planeAnchor)
        let mesh = makeMesh(for: planeAnchor)

        anchorEntity.addChild(mesh)
        anchorEntity.isEnabled = isVisible
        arView.scene.addAnchor(anchorEntity)
        anchors[planeAnchor.identifier] = anchorEntity
        meshes[planeAnchor.identifier] = mesh
    }

    func update(_ planeAnchor: ARPlaneAnchor) {
        guard let oldMesh = meshes[planeAnchor.identifier],
              let anchorEntity = anchors[planeAnchor.identifier] else {
            return
        }

        oldMesh.removeFromParent()

        let mesh = makeMesh(for: planeAnchor)
        anchorEntity.addChild(mesh)
        anchorEntity.isEnabled = isVisible
        meshes[planeAnchor.identifier] = mesh
    }

    @discardableResult
    func toggleVisible() -> Bool {
        setVisible(!isVisible)
        return isVisible
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        for anchor in anchors.values {
            anchor.isEnabled = visible
        }
    }

    func remove(_ identifier: UUID) {
        meshes[identifier]?.removeFromParent()
        anchors[identifier]?.removeFromParent()
        meshes.removeValue(forKey: identifier)
        anchors.removeValue(forKey: identifier)
    }

    func removeAll() {
        for anchor in anchors.values {
            anchor.removeFromParent()
        }

        anchors.removeAll()
        meshes.removeAll()
    }

    private func makeMesh(for planeAnchor: ARPlaneAnchor) -> ModelEntity {
        let extent = planeAnchor.planeExtent
        let mesh = Self.makeGridPlaneMesh(width: extent.width, depth: extent.height)
        let material = Self.makeGridMaterial()
        let entity = ModelEntity(mesh: mesh, materials: [material])

        entity.transform.translation = planeAnchor.center
        entity.transform.rotation = simd_quatf(
            angle: extent.rotationOnYAxis,
            axis: SIMD3<Float>(0, 1, 0)
        )

        return entity
    }

    private static func makeGridPlaneMesh(width: Float, depth: Float) -> MeshResource {
        let halfWidth = width / 2
        let halfDepth = depth / 2
        let uvScale: Float = 1.25

        let positions: [SIMD3<Float>] = [
            [-halfWidth, 0, -halfDepth],
            [halfWidth, 0, -halfDepth],
            [halfWidth, 0, halfDepth],
            [-halfWidth, 0, halfDepth]
        ]
        let normals = Array(repeating: SIMD3<Float>(0, 1, 0), count: 4)
        let uvs: [SIMD2<Float>] = [
            [0, 0],
            [width * uvScale, 0],
            [width * uvScale, depth * uvScale],
            [0, depth * uvScale]
        ]
        let triangleIndices: [UInt32] = [0, 2, 1, 0, 3, 2]

        var descriptor = MeshDescriptor(name: "PlaneGrid")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(triangleIndices)

        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            fatalError("Plane MeshResource 생성 실패: \(error)")
        }
    }

    private static func makeGridMaterial() -> Material {
        var material = UnlitMaterial()
        material.color = .init(
            tint: UIColor.white.withAlphaComponent(0.85),
            texture: .init(GridTexture.resource)
        )
        material.blending = .transparent(opacity: 0.85)
        return material
    }
}
