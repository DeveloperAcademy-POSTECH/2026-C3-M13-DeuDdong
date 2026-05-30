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

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("1단계 햅틱") {
                        try? HapticManager.shared.playSimple()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)

                    Button("2단계 햅틱") {
                        try? HapticManager.shared.playFold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }

                ARStatusOverlayView(state: planeState)
                    .padding(.horizontal, 20)
            }
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
