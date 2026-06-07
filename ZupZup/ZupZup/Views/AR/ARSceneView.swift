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
    @State private var burstController = DebugBurstController()
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
                burstController: burstController,
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

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                #if DEBUG
                HapticDebugView()
                Button("파티클 터뜨리기") {
                    burstController.fire()
                }
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

                if planeState == .ready {
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
    }
}

#Preview {
    ARSceneView()
}
