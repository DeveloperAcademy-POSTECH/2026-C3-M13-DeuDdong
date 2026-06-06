//
//  ARSceneView.swift -> AR MainView!!!
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import SwiftUI

struct ARSceneView: View {
    @State private var planeState: ARState = .searching
    @State private var sessionManager = ARSessionManager()
    @State private var placementManager = PlacementManager()
    @State private var emotionRuntime = EmotionRuntime(configuration: .conversation)
    #if DEBUG
    @State private var handTrackingManager = HandTrackingManager.shared
    @State private var burstController = DebugBurstController()
    #endif

    var body: some View {
        ZStack {
            #if DEBUG
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                planeState: $planeState,
                burstController: burstController
            )
            .ignoresSafeArea()
            #else
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                planeState: $planeState
            )
            .ignoresSafeArea()
            #endif

            #if DEBUG
            VStack(alignment: .leading, spacing: 8) {
                ARDebugOverlayView(
                    gesture: handTrackingManager.currentGesture,
                    distance: handTrackingManager.distance
                )

                MLDebugOverlayView(runtime: emotionRuntime)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #endif

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                #if DEBUG
                HapticDebugView()
                Button("파티클 터뜨리기") {
                    burstController.fire()
                }
                .buttonStyle(.borderedProminent)
                #endif

                ARStatusOverlayView(state: planeState)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            if !sessionManager.isWorldTrackingSupported {
                planeState = .unsupported //
            }

            emotionRuntime.onOrbEvent = { event in
                placementManager.placeOrb(event: event)
            }
        }
        .task {
            await emotionRuntime.start()
        }
        .onDisappear {
            emotionRuntime.stop()
            emotionRuntime.onOrbEvent = nil
        }
    }
}

#Preview {
    ARSceneView()
}
