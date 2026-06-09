//
//  ARViewContainer.swift -> SwiftUI랑 ARView(from RealityKit)을 연결해주는 다리입니다!! (정확히는 래퍼)
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    let sessionManager: ARSessionManager
    let placementManager: PlacementManager
    let emotionRuntime: EmotionRuntimeManaging
    let orbEventPlacementController: OrbEventPlacementController
    @Binding var planeState: ARState
    @Binding var isPlaneVisualizationVisible: Bool
    let isCollecting: Bool
    
    #if DEBUG
    let burstController: DebugBurstController
    let orbPlacementController: DebugOrbPlacementController
    let gridController: DebugGridController
    #endif

    func makeCoordinator() -> ARSceneCoordinator {
        ARSceneCoordinator(
            sessionManager: sessionManager,
            placementManager: placementManager,
            emotionRuntime: emotionRuntime
        ) { state in
            planeState = state
            }
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
            )
        context.coordinator.install(on: arView)
        context.coordinator.setPlaneVisualizationVisible(isPlaneVisualizationVisible)
        context.coordinator.setCollectionMode(isCollecting)
        orbEventPlacementController.trigger = { [weak coordinator = context.coordinator] event in
            coordinator?.placeOrb(event: event)
        }
        #if DEBUG
        burstController.trigger = { [weak coordinator = context.coordinator] in
            coordinator?.triggerDebugBurst()
        }
        orbPlacementController.trigger = { [weak coordinator = context.coordinator] count in
            coordinator?.triggerDebugOrbPlacement(count: count)
        }
        gridController.toggle = { [weak coordinator = context.coordinator] in
            coordinator?.toggleGridVisibility() ?? true
        }
        #endif
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.setPlaneVisualizationVisible(isPlaneVisualizationVisible)
        context.coordinator.setCollectionMode(isCollecting)
        context.coordinator.updatePlaneStateHandler { state in
            planeState = state
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneCoordinator) {
        uiView.session.pause()
    }
}
