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
    @State private var remainingConversationSeconds = 180
    @State private var secondsWithoutOrb = 0
    @State private var trackedOrbCount = 0
    @State private var showsPraisePrompt = false
    #if DEBUG
    @State private var handTrackingManager = HandTrackingManager.shared
    @State private var orbPlacementController = DebugOrbPlacementController()
    @State private var gridController = DebugGridController()
    @State private var isGridVisible = true
    #endif

    var body: some View {
        ZStack {
            #if DEBUG
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                planeState: $planeState,
                orbPlacementController: orbPlacementController,
                gridController: gridController
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

            if isConversationStarted {
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
            }

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                #if DEBUG
                HapticDebugView()
                .buttonStyle(.borderedProminent)
                Button("구슬 물리 테스트") {
                    orbPlacementController.fire()
                }
                .buttonStyle(.borderedProminent)
                Button(isGridVisible ? "그리드 끄기" : "그리드 켜기") {
                    isGridVisible = gridController.toggleVisibility()
                }
                .buttonStyle(.bordered)
                #endif

                if planeState == .ready && isConversationStarted {
                    ConversationAudioLevelOverlay(speechState: emotionRuntime.speechState)
                        .padding(.bottom, 8)
                }

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
        await runConversationTimer()
    }

    @MainActor
    private func runConversationTimer() async {
        remainingConversationSeconds = 180
        secondsWithoutOrb = 0
        trackedOrbCount = emotionRuntime.emittedOrbEvents.count
        showsPraisePrompt = false

        while remainingConversationSeconds > 0 {
            try? await Task.sleep(for: .seconds(1))

            if Task.isCancelled {
                return
            }

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
