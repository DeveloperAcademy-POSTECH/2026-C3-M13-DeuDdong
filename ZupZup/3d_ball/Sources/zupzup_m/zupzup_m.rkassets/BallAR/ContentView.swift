//
//  ContentView.swift
//  BallAR
//
//  Created by YUJIN JEONG on 6/5/26.
//

import SwiftUI
import RealityKit
import ARKit

class ARCoordinator: NSObject {
    var arView: ARView?
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = arView else { return }
        
        let translation = gesture.translation(in: arView)
        let rotationY = Float(translation.x) * 0.01
        let rotationX = Float(translation.y) * 0.01
        
        for anchor in arView.scene.anchors {
            for entity in anchor.children {
                entity.transform.rotation *= simd_quatf(angle: rotationY, axis: [0, 1, 0])
                entity.transform.rotation *= simd_quatf(angle: rotationX, axis: [1, 0, 0])
            }
        }
        
        gesture.setTranslation(.zero, in: arView)
    }
    
    func placeModel(named modelName: String) {
        guard let arView = arView,
              let model = try? ModelEntity.loadModel(named: modelName) else {
            print("모델 로드 실패: \(modelName)")
            return
        }
        
        // 랜덤 위치 (중앙 기준 주변)
        let randomX = Float.random(in: -0.4...0.4)
        let randomY = Float.random(in: -0.2...0.2)
        let randomZ = Float.random(in: -1.0 ... -0.4)
        
        let anchor = AnchorEntity(world: [randomX, randomY, randomZ])
        anchor.addChild(model)
        arView.scene.addAnchor(anchor)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let modelName: String
    
    func makeCoordinator() -> ARCoordinator {
        return ARCoordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(ARCoordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(pan)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.placeModel(named: modelName)
    }
}

struct ContentView: View {
    let models: [(name: String, file: String)] = [
        ("love", "affectionBall")
    ]
    @State private var selectedModel = "affectionBall"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelName: selectedModel)
                .ignoresSafeArea()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(models, id: \.file) { model in
                        Button(model.name) {
                            selectedModel = model.file
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedModel == model.file ? Color.pink : Color.white.opacity(0.8))
                        .foregroundColor(selectedModel == model.file ? .white : .black)
                        .cornerRadius(20)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
    }
}
