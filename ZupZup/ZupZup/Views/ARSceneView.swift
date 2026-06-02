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
    @StateObject private var emotionRuntime = EmotionRuntime(configuration: .conversation)
    
    var body: some View {
        ZStack {
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                planeState: $planeState //
            )
            .ignoresSafeArea() // 카메라 전체 화면 덮으려고 넣음

            VStack(spacing: 12) {
                ARDebugOverlayView(runtime: emotionRuntime)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer(minLength: 0)

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
