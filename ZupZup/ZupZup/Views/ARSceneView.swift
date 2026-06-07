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
    @State private var countdownCuePlayer = ConversationCountdownCuePlayer()
    @State private var countdownValue: Int?
    @State private var isConversationStarted = false
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

            if let countdownValue {
                CountdownOverlay(count: countdownValue)
                    .transition(.opacity)
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
            await startConversationAfterCountdown()
        }
        .onDisappear {
            countdownCuePlayer.stop()
            emotionRuntime.stop()
            emotionRuntime.onOrbEvent = nil
        }
    }

    @MainActor
    private func startConversationAfterCountdown() async {
        guard !isConversationStarted else { return }

        countdownCuePlayer.speakIntro()

        for count in stride(from: 3, through: 1, by: -1) {
            countdownValue = count
            countdownCuePlayer.playTick()
            try? await Task.sleep(for: .seconds(1))

            if Task.isCancelled {
                countdownValue = nil
                return
            }
        }

        countdownValue = nil
        isConversationStarted = true
        await emotionRuntime.start()
    }
}

#Preview {
    ARSceneView()
}
