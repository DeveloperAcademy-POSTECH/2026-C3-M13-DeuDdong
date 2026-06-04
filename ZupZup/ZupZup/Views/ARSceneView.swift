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
    #endif

    var body: some View {
        ZStack {
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                planeState: $planeState //
            )
            .ignoresSafeArea() // 카메라 전체 화면 덮으려고 넣음

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
