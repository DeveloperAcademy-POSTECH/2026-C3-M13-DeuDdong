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
    @Binding var planeState: ARState
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
        #if DEBUG
        burstController.trigger = { [weak coordinator = context.coordinator] in
            coordinator?.triggerDebugBurst()
        }
        orbPlacementController.trigger = { [weak coordinator = context.coordinator] in
            coordinator?.triggerDebugOrbPlacement()
        }
        gridController.toggle = { [weak coordinator = context.coordinator] in
            coordinator?.toggleGridVisibility() ?? true
        }
        #endif
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updatePlaneStateHandler { state in
            planeState = state
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneCoordinator) {
        uiView.session.pause()
    }
}
