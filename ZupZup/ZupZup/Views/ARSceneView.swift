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
    @State private var remainingConversationSeconds = 180
    @State private var secondsWithoutOrb = 0
    @State private var trackedOrbCount = 0
    @State private var showsPraisePrompt = false
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

            VStack(spacing: 8) {
                ConversationTimerView(remainingSeconds: remainingConversationSeconds)

                if showsPraisePrompt {
                    StatusToast(
                        text: "칭찬의 한마디를 해보세요",
                        systemName: "heart.text.square.fill",
                        isWarning: false
                    )
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
                    .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 28)
            .allowsHitTesting(false)

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
        .task {
            await runConversationTimer()
        }
        .onDisappear {
            emotionRuntime.stop()
            emotionRuntime.onOrbEvent = nil
        }
    }

    @MainActor
    private func runConversationTimer() async {
        remainingConversationSeconds = 180
        secondsWithoutOrb = 0
        trackedOrbCount = emotionRuntime.emittedOrbEvents.count
        showsPraisePrompt = false

        while remainingConversationSeconds > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }

            remainingConversationSeconds -= 1
            updatePraisePromptState()
        }
    }

    private func updatePraisePromptState() {
        let currentOrbCount = emotionRuntime.emittedOrbEvents.count

        if currentOrbCount > trackedOrbCount {
            trackedOrbCount = currentOrbCount
            secondsWithoutOrb = 0
            showsPraisePrompt = false
            return
        }

        secondsWithoutOrb += 1
        showsPraisePrompt = secondsWithoutOrb >= 60
    }
}

#Preview {
    ARSceneView()
}
