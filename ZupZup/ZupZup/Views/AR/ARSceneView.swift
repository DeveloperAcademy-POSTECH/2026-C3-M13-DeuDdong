import SwiftUI

struct ARSceneView: View {
    var onFinishConversation: () -> Void = {}
    var onReturnHome: () -> Void = {}
    @State private var planeState: ARState = .searching
    @State private var sessionManager = ARSessionManager()
    @State private var placementManager = PlacementManager()
    @State private var emotionRuntime = EmotionRuntime(configuration: .conversation)
    @State private var countdownCuePlayer = ConversationCountdownCuePlayer()
    @State private var orbEventPlacementController = OrbEventPlacementController()
    @State private var conversationFlowTask: Task<Void, Never>?
    @State private var countdownValue: Int?
    @State private var isConversationStarted = false
    @State private var hasConfirmedSpaceRecognition = false
    @State private var hasLockedSpeakerRecognition = false
    @State private var hasStartedConversationFlow = false
    @State private var isConversationFinished = false
    @State private var isCollecting = false
    @State private var remainingConversationSeconds = 180
    @State private var secondsWithoutOrb = 0
    @State private var trackedOrbEventID: UUID?
    @State private var showsPraisePrompt = false
    @State private var activeOverlay: AROverlayType?
    @State private var isPlaneVisualizationVisible = true
    #if DEBUG
    @State private var handTrackingManager = HandTrackingManager.shared
    @State private var burstController = DebugBurstController()
    @State private var orbPlacementController = DebugOrbPlacementController()
    @State private var gridController = DebugGridController()
    #endif

    var body: some View {
        ZStack {
            #if DEBUG
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                orbEventPlacementController: orbEventPlacementController,
                planeState: $planeState,
                isPlaneVisualizationVisible: $isPlaneVisualizationVisible,
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
                orbEventPlacementController: orbEventPlacementController,
                planeState: $planeState,
                isPlaneVisualizationVisible: $isPlaneVisualizationVisible
            )
            .ignoresSafeArea()
            #endif

            #if DEBUG
            if shouldShowDeveloperDebug {
                DeveloperDebugPanelView(
                    gesture: handTrackingManager.currentGesture,
                    distance: handTrackingManager.distance,
                    runtime: emotionRuntime,
                    burstAction: { burstController.fire() },
                    testOrbAction: { orbPlacementController.fire() },
                    addOrbAction: { orbPlacementController.fire() },
                    addFiveOrbsAction: { orbPlacementController.fire(count: 5) }
                )
            }
            #endif

            if shouldShowSpaceRecognition {
                SpaceRecognitionStepView(
                    isReady: planeState == .ready,
                    showsPreviewBackground: false,
                    backAction: resetRecognitionFlow,
                    nextAction: confirmSpaceRecognition
                )
                .transition(.opacity)
            }

            if shouldShowSpeakerRecognition {
                DistanceRecognitionStepView(
                    progress: speakerRecognitionProgress,
                    isReady: isSpeakerRecognitionReady,
                    showsPreviewBackground: false,
                    backAction: resetRecognitionFlow,
                    nextAction: confirmSpeakerRecognition
                )
                .transition(.opacity)
            }

            if shouldShowMouthTrackingOverlay {
                MouthTrackingOverlay(result: emotionRuntime.latestFaceTrackingResult)
                    .transition(.opacity)
            }

            if isConversationStarted {
                VStack(spacing: 8) {
                    ZStack {
                        ConversationTimerView(remainingSeconds: remainingConversationSeconds)

                        HStack {
                            ARHomeButtonDark {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    activeOverlay = .homeExit
                                }
                            }
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    activeOverlay = .conversationEnd
                                }
                            } label: {
                                Text("대화 종료")
                                    .font(ZZFont.body)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

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
            }

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                if planeState == .ready && isConversationStarted {
                    ConversationAudioLevelOverlay(speechState: emotionRuntime.speechState)
                        .padding(.bottom, 8)
                }

                if !shouldShowSpaceRecognition && !shouldShowSpeakerRecognition {
                    ARStatusOverlayView(state: planeState)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }

            if let countdownValue {
                ZStack {
                    CountdownOverlay(count: countdownValue)

                    VStack {
                        HStack {
                            ARBackButtonDark {
                                resetRecognitionFlow()
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 78)

                        Spacer()
                    }
                }
                .transition(.opacity)
            }

            activeOverlayView

            if isCollecting {
                ARCollectView(
                    onReturnHome: onReturnHome,
                    onCompleted: onFinishConversation
                )
                .transition(.opacity)
            }
        }
        .preventsIdleTimer()
        .onChange(of: isCollecting) { _, collecting in
            if collecting {
                placementManager.placeBottleInFrontOfCamera()
            }
        }
        .onAppear {
            if !sessionManager.isWorldTrackingSupported {
                planeState = .unsupported //
            }

            emotionRuntime.onOrbEvent = { event in
                orbEventPlacementController.fire(event)
            }
        }
        .onDisappear {
            conversationFlowTask?.cancel()
            conversationFlowTask = nil
            countdownCuePlayer.stop()
            emotionRuntime.stop()
            emotionRuntime.onOrbEvent = nil
        }
    }
}

private extension ARSceneView {
    private var shouldShowSpaceRecognition: Bool {
        !hasConfirmedSpaceRecognition && !hasStartedConversationFlow && !isConversationFinished
    }

    private var shouldShowSpeakerRecognition: Bool {
        planeState == .ready
            && hasConfirmedSpaceRecognition
            && !hasLockedSpeakerRecognition
            && !hasStartedConversationFlow
            && !isConversationFinished
            && countdownValue == nil
            && activeOverlay == nil
    }

    private var shouldShowMouthTrackingOverlay: Bool {
        planeState == .ready && hasConfirmedSpaceRecognition && !isConversationFinished
    }

    #if DEBUG
    private var shouldShowDeveloperDebug: Bool {
        hasStartedConversationFlow && !isConversationFinished
    }
    #endif

    private var speakerRecognitionProgress: Double {
        min(1, currentSpeakerRecognitionScore / 0.58)
    }

    private var isSpeakerRecognitionReady: Bool {
        hasLockedSpeakerRecognition || (shouldShowSpeakerRecognition && currentSpeakerRecognitionScore >= 0.58)
    }

    private var currentSpeakerRecognitionScore: Double {
        guard planeState == .ready else { return 0 }
        guard let result = emotionRuntime.latestFaceTrackingResult else { return 0 }

        return result.candidates
            .map(speakerRecognitionScore(for:))
            .max() ?? 0
    }

    @ViewBuilder
    private var activeOverlayView: some View {
        switch activeOverlay {
        case .homeExit:
            HomeExitOverlay(
                cancelAction: { activeOverlay = nil },
                confirmAction: onReturnHome
            )
        case .conversationEnd:
            ConversationEndOverlay(
                cancelAction: { activeOverlay = nil },
                confirmAction: {
                    finishConversation(showOverlay: false)
                    activeOverlay = nil
                    withAnimation(.easeOut(duration: 0.2)) {
                        isCollecting = true
                    }
                }
            )
        case .noOrb:
            NoOrbOverlay(
                restartAction: restartConversationFlow,
                homeAction: onReturnHome
            )
        case .none:
            EmptyView()
        default:
            EmptyView()
        }
    }

    private func speakerRecognitionScore(for candidate: FaceTrackingCandidate) -> Double {
        let guideCenter = CGPoint(x: 0.5, y: 0.42)
        let xDistance = candidate.faceCenter.x - guideCenter.x
        let yDistance = candidate.faceCenter.y - guideCenter.y
        let centerDistance = sqrt(Double(xDistance * xDistance + yDistance * yDistance))
        let centerScore = max(0, 1 - centerDistance / 0.42)
        let faceWidth = Double(candidate.faceBounds.width)
        let sizeScore = min(1, max(0, (faceWidth - 0.09) / 0.13))
        let detectionBonus = 0.18

        return min(1, detectionBonus + centerScore * 0.52 + sizeScore * 0.30)
    }

    private func startConversationFlowIfNeeded() {
        guard conversationFlowTask == nil, isSpeakerRecognitionReady else { return }

        withAnimation(.easeOut(duration: 0.12)) {
            hasLockedSpeakerRecognition = true
        }
        conversationFlowTask = Task { @MainActor in
            await startConversationAfterCountdown()
            conversationFlowTask = nil
        }
    }

    private func confirmSpaceRecognition() {
        guard planeState == .ready else { return }
        withAnimation(.easeOut(duration: 0.12)) {
            hasConfirmedSpaceRecognition = true
            isPlaneVisualizationVisible = false
        }
    }

    private func confirmSpeakerRecognition() {
        if isSpeakerRecognitionReady { startConversationFlowIfNeeded() }
    }

    @MainActor
    private func startConversationAfterCountdown() async {
        guard !isConversationStarted,
              !hasStartedConversationFlow,
              !isConversationFinished else {
            return
        }

        hasStartedConversationFlow = true
        countdownCuePlayer.speakIntro()

        for count in stride(from: 3, through: 1, by: -1) {
            countdownValue = count
            countdownCuePlayer.playTick()
            try? await Task.sleep(for: .seconds(1))

            if Task.isCancelled {
                countdownValue = nil
                hasStartedConversationFlow = false
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
        trackedOrbEventID = emotionRuntime.latestOrbEvent?.id
        showsPraisePrompt = false

        while remainingConversationSeconds > 0 {
            try? await Task.sleep(for: .seconds(1))

            if Task.isCancelled {
                return
            }

            remainingConversationSeconds -= 1
            updatePraisePromptState()
        }

        finishConversation(showOverlay: true)
    }

    private func updatePraisePromptState() {
        let currentOrbEventID = emotionRuntime.latestOrbEvent?.id
        if let currentOrbEventID, currentOrbEventID != trackedOrbEventID {
            trackedOrbEventID = currentOrbEventID
            secondsWithoutOrb = 0
            showsPraisePrompt = false
            return
        }

        secondsWithoutOrb += 1
        showsPraisePrompt = secondsWithoutOrb >= 60
    }

    private func finishConversation(showOverlay: Bool) {
        emotionRuntime.stop()
        countdownCuePlayer.stop()
        isConversationStarted = false
        isConversationFinished = true
        showsPraisePrompt = false
        countdownValue = nil

        guard showOverlay else { return }
        if emotionRuntime.emittedOrbEventCount == 0 {
            activeOverlay = .noOrb
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                isCollecting = true
            }
        }
    }

    private func restartConversationFlow() {
        conversationFlowTask?.cancel()
        conversationFlowTask = nil
        activeOverlay = nil
        isConversationFinished = false
        hasConfirmedSpaceRecognition = true
        isPlaneVisualizationVisible = false
        hasLockedSpeakerRecognition = false
        hasStartedConversationFlow = false
        isConversationStarted = false
        remainingConversationSeconds = 180
        secondsWithoutOrb = 0
        trackedOrbEventID = emotionRuntime.latestOrbEvent?.id
        showsPraisePrompt = false
        startConversationFlowIfNeeded()
    }

    private func resetRecognitionFlow() {
        conversationFlowTask?.cancel()
        conversationFlowTask = nil
        activeOverlay = nil
        countdownCuePlayer.stop()
        countdownValue = nil
        hasConfirmedSpaceRecognition = false
        isPlaneVisualizationVisible = true
        hasLockedSpeakerRecognition = false
        hasStartedConversationFlow = false
        isConversationFinished = false
        isConversationStarted = false
        emotionRuntime.stop()
    }
}
