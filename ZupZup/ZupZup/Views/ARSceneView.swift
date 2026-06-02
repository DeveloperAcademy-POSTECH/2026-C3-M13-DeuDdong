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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                planeState: $planeState //
            )
            .ignoresSafeArea() // 카메라 전체 화면 덮으려고 넣음

            VStack(spacing: 16) {
                ARStatusOverlayView(state: planeState)

                Button {
                    sessionManager.burst(emotion: .affection)
                } label: {
                    Text("💗 Affection")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .onAppear {
            if !sessionManager.isWorldTrackingSupported {
                planeState = .unsupported //
            }
        }
    }
}

#Preview {
    ARSceneView()
}
