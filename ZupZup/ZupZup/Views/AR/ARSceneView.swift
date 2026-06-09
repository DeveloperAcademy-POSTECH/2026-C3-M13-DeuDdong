import SwiftUI

struct ARSceneView: View {
    // MARK: - [내비게이션 액션 클로저]
    var onFinishConversation: () -> Void = {} // 5단계 수집까지 완료된 후 최종 화면으로 이동
    var onReturnHome: () -> Void = {}         // 홈으로 완전히 돌아갈 때 호출
    
    // MARK: - [AR 및 감정 분석 핵심 엔진]
    @State private var planeState: ARState = .searching // AR 바닥 평면 인식 상태 트래킹
    @State private var sessionManager = ARSessionManager()
    @State private var placementManager = PlacementManager()
    @State private var emotionRuntime = EmotionRuntime(configuration: .conversation) // 실시간 음성/표정 분석
    @State private var countdownCuePlayer = ConversationCountdownCuePlayer()         // 안내 효과음 플레이어
    @State private var orbEventPlacementController = OrbEventPlacementController()   // 감정 구슬 3D 배치 제어
    
    // MARK: - [비동기 흐름 및 단계 제어 플래그]
    @State private var conversationFlowTask: Task<Void, Never>? // 타이머 및 카운트다운을 관리하는 비동기 태스크
    @State private var countdownValue: Int?                     // 3단계 진입 시 화면에 뿌려줄 3, 2, 1 숫자
    @State private var isConversationStarted = false            // 4단계(대화 진행) 시작 여부 플래그
    @State private var hasConfirmedSpaceRecognition = false     // 1단계(공간 인식) 수동 확인 완료 여부
    @State private var hasLockedSpeakerRecognition = false      // 2단계(화자 인식) 조건 통과 및 고정 여부
    @State private var hasStartedConversationFlow = false       // 카운트다운을 포함한 대화 시퀀스 진입 여부
    @State private var isConversationFinished = false           // 4단계(3분 대화) 타이머 종료 여부
    
    // 🔮 [5단계 핵심 상태]
    @State private var isCollecting = false                     // 4단계 종료 후 '5단계: 구슬 수집 단계' 활성화 플래그
    
    // MARK: - [실시간 상태 및 모니터링 변수]
    @State private var remainingConversationSeconds = 180       // 4단계 대화 시간 (3분 타이머)
    @State private var secondsWithoutOrb = 0                    // 구슬 미생성 침묵 시간 누적 (60초 체크용)
    @State private var trackedOrbEventID: UUID?                 // 가장 최근에 생성된 구슬 고유 ID 홀더
    @State private var showsPraisePrompt = false                // "칭찬의 한마디를 해보세요" 가이드 토스트 노출 상태
    @State private var activeOverlay: AROverlayType?            // 현재 화면에 띄울 상단 공통 팝업 종류
    @State private var isPlaneVisualizationVisible = true       // 노란색 AR 바닥 인식 가이드선 노출 여부
    
    // MARK: - [개발자 디버그 매니저]
    #if DEBUG
    @State private var handTrackingManager = HandTrackingManager.shared
    @State private var orbPlacementController = DebugOrbPlacementController()
    @State private var gridController = DebugGridController()
    #endif

    // MARK: - [메인 렌더링 바디]
    var body: some View {
        ZStack {
            // -------------------------------------------------------------------------
            // [기반 레이어] 실제 카메라 피드 및 3D 그래픽 렌더링 컨테이너
            // -------------------------------------------------------------------------
            #if DEBUG
            ARViewContainer(
                sessionManager: sessionManager,
                placementManager: placementManager,
                emotionRuntime: emotionRuntime,
                orbEventPlacementController: orbEventPlacementController,
                planeState: $planeState,
                isPlaneVisualizationVisible: $isPlaneVisualizationVisible,
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

            // -------------------------------------------------------------------------
            // [디버그 레이어] 개발용 패널 (일반 빌드 시 완전히 제외됨)
            // -------------------------------------------------------------------------
            #if DEBUG
            if shouldShowDeveloperDebug {
                DeveloperDebugPanelView(
                    gesture: handTrackingManager.currentGesture,
                    distance: handTrackingManager.distance,
                    runtime: emotionRuntime,
                    testOrbAction: { orbPlacementController.fire() },
                    addOrbAction: { orbPlacementController.fire() },
                    addFiveOrbsAction: { orbPlacementController.fire(count: 5) }
                )
            }
            #endif

            // -------------------------------------------------------------------------
            // 🛑 [1단계: 공간 인식] 바닥 평면을 탐색하고 사용자 승인을 기다리는 단계
            // -------------------------------------------------------------------------
            if shouldShowSpaceRecognition {
                SpaceRecognitionStepView(
                    isReady: planeState == .ready, // 시스템이 바닥 평면 스캔을 완료하면 활성화됨
                    showsPreviewBackground: false,
                    backAction: resetRecognitionFlow,
                    nextAction: confirmSpaceRecognition // 버튼 클릭 시 -> 2단계로 이동
                )
                .transition(.opacity)
            }

            // -------------------------------------------------------------------------
            // 🛑 [2단계: 화자 인식] 사용자가 대화하기 좋은 적정 거리와 정중앙에 위치했는지 검증하는 단계
            // -------------------------------------------------------------------------
            if shouldShowSpeakerRecognition {
                DistanceRecognitionStepView(
                    progress: speakerRecognitionProgress, // 얼굴 조준 정확도 게이지 바 비율
                    isReady: isSpeakerRecognitionReady,   // 점수 조건(0.58)을 충족하면 활성화됨
                    showsPreviewBackground: false,
                    backAction: resetRecognitionFlow,
                    nextAction: confirmSpeakerRecognition // 버튼 클릭 시 -> 3단계 카운트다운 체인 시퀀스 기동
                )
                .transition(.opacity)
            }

            // [얼굴 랜드마크 오버레이] 화자 인식을 돕기 위해 실시간 입모양 및 얼굴 윤곽선 메쉬 가이드를 그리는 뷰
            if shouldShowMouthTrackingOverlay {
                MouthTrackingOverlay(result: emotionRuntime.latestFaceTrackingResult)
                    .transition(.opacity)
            }

            // -------------------------------------------------------------------------
            // 🛑 [4단계: 대화 진행] 본격적으로 3분 타이머가 돌아가며 실시간 대화를 나누는 단계
            // -------------------------------------------------------------------------
            if isConversationStarted {
                ZStack {

                    // 음파

                    VStack {
                        Spacer()

                        ConversationAudioLevelOverlay(
                            speechState: emotionRuntime.speechState
                        )

                        Spacer()
                            .frame(height: 30)
                    }

                    // 상단 HUD

                    VStack {

                        ZStack {

                            ConversationTimerView(
                                remainingSeconds: remainingConversationSeconds
                            )

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
                            .padding(.top, 12)
                        }

                        Spacer()
                    }
                    .padding(.top, 0)
                }
            }

            // -------------------------------------------------------------------------
            // [하단 보조 컴포넌트 레이어] 음성 파형 비주얼라이저 및 실시간 AR 에러 피드백 상태바
            // -------------------------------------------------------------------------
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                // 4단계 대화방이 활성화되었을 때만 하단에 사용자의 음성 볼륨에 따라 역동적인 파형 애니메이션 노출
                if planeState == .ready && isConversationStarted {
                    ConversationAudioLevelOverlay(speechState: emotionRuntime.speechState)
                        .padding(.bottom, 8)
                }

            }

            // -------------------------------------------------------------------------
            // 🛑 [3단계: 카운트다운] 대화방에 진입하기 직전, 화면 중앙에 3, 2, 1 카운트를 세는 단계
            // -------------------------------------------------------------------------
            if let countdownValue {
                ZStack {
                    CountdownOverlay(count: countdownValue) // 중앙 거대 숫자 연출

                    VStack {
                        HStack {
                            // 카운트다운 도중 뒤로 가기 터치 시 전체 프로세스 리셋 후 1단계로 강제 롤백
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

            // -------------------------------------------------------------------------
            // [최상단 공통 팝업 모듈 레이어] zIndex 바인딩을 통해 최우선 오버레이 계층 보장
            // -------------------------------------------------------------------------
            activeOverlayView

            // -------------------------------------------------------------------------
            // 🛑 [5단계: 대화 종료 후 구슬 수집] 대화 종료 확정 후 화면을 수집 전용으로 완전 교체하는 단계
            // -------------------------------------------------------------------------
            if isCollecting {
                ARCollectView(
                    onReturnHome: onReturnHome,          // 수집 화면 내에서 홈 이동 터치 시 처리
                    onCompleted: onFinishConversation    // 모든 수집을 끝마쳤을 때 최종 보상 결과창으로 점프
                )
                .transition(.opacity)
            }
        }
        .preventsIdleTimer() // 대화 및 수집 도중 기기 화면이 꺼지는 현상 하드웨어 레벨 방지
        // -------------------------------------------------------------------------
        // 🔮 [5단계 전용 트리거] 5단계 수집 페이즈가 활성화(`isCollecting = true`)되는 순간 작동
        // -------------------------------------------------------------------------
        .onChange(of: isCollecting) { _, collecting in
            if collecting {
                // 사용자의 전방 카메라 화면 중심 기준 알맞은 3D 좌표 공간에 구슬들을 담을 '가상 유리병(Bottle)'을 소환 배치
                placementManager.placeBottleInFrontOfCamera()
            }
        }
        .onAppear {
            // 기기의 ARKit 월드 트래킹 기능 지원 한계 검사
            if !sessionManager.isWorldTrackingSupported {
                planeState = .unsupported
            }

            // 4단계 대화 중 실시간으로 유저의 긍정적인 감정이 포착될 때마다 해당 공간 좌표에 3D 감정 구슬 노드 인스턴스 생성
            emotionRuntime.onOrbEvent = { event in
                orbEventPlacementController.fire(event)
            }
        }
        .onDisappear {
            // 메모리 누수 방지를 위해 화면 이탈 시 실행 중이던 모든 비동기 스레드 타이머 및 오디오 플레이어 안전 파괴 청소
            conversationFlowTask?.cancel()
            conversationFlowTask = nil
            countdownCuePlayer.stop()
            emotionRuntime.stop()
            emotionRuntime.onOrbEvent = nil
        }
    }
}

// MARK: - ⚙️ 단계 흐름 제어 조건식 및 상태 변환 비즈니스 로직
private extension ARSceneView {
    
    // [1단계 가시성 제어] 공간 인식이 미완료되었고, 대화 스케줄이 아예 시작 전이며, 대화가 끝나지 않았을 때 표시
    private var shouldShowSpaceRecognition: Bool {
        !hasConfirmedSpaceRecognition && !hasStartedConversationFlow && !isConversationFinished
    }

    // [2단계 가시성 제어] 바닥 탐색이 준비되었고, 1단계를 승인했으며, 화자 인스턴스 고정 전이면서 카운트다운 전일 때 표시
    private var shouldShowSpeakerRecognition: Bool {
        planeState == .ready
            && hasConfirmedSpaceRecognition
            && !hasLockedSpeakerRecognition
            && !hasStartedConversationFlow
            && !isConversationFinished
            && countdownValue == nil
            && activeOverlay == nil
    }

    // [얼굴 추적 메쉬 가시성 제어] 바닥 준비 완료 및 공간 인식 승인을 거쳤으며 대화 타이머가 돌아가는 중에만 노출
    private var shouldShowMouthTrackingOverlay: Bool {
        planeState == .ready && hasConfirmedSpaceRecognition && !isConversationFinished
    }

    #if DEBUG
    // [개발자 패널 가시성 제어] 대화 시퀀스가 활성화되어 돌아가는 중이고 대화가 종료되기 전인 디버깅 순간 노출
    private var shouldShowDeveloperDebug: Bool {
        hasStartedConversationFlow && !isConversationFinished
    }
    #endif

    // 화자 인식 완성도 프로그레스 게이지 바 연동 스케일링 식 (임계점 점수인 0.58을 백분율 최고 수치 1.0으로 매핑)
    private var speakerRecognitionProgress: Double {
        min(1, currentSpeakerRecognitionScore / 0.58)
    }

    // 화자 인식 성공 임계치 충족 판단 플래그 (점수 커트라인인 0.58을 넘겼거나 강제로 락을 가했을 때 참)
    private var isSpeakerRecognitionReady: Bool {
        hasLockedSpeakerRecognition || (shouldShowSpeakerRecognition && currentSpeakerRecognitionScore >= 0.58)
    }

    // 현재 기기 카메라 프레임에 포착된 모든 얼굴 후보들 중 최적의 가이드 조준 점수를 산출
    private var currentSpeakerRecognitionScore: Double {
        guard planeState == .ready else { return 0 }
        guard let result = emotionRuntime.latestFaceTrackingResult else { return 0 }

        return result.candidates
            .map(speakerRecognitionScore(for:))
            .max() ?? 0
    }

    // 상단 팝업 뷰 분기 팩토리 (zIndex 적용 계층)
    @ViewBuilder
    private var activeOverlayView: some View {
        switch activeOverlay {
        case .homeExit:
            HomeExitOverlay(
                cancelAction: { activeOverlay = nil },
                confirmAction: onReturnHome
            )
        case .conversationEnd:
            // 4단계 대화 중 유저가 자발적으로 우측 상단 '대화 종료' 버튼을 눌렀을 때 등장하는 확인창
            ConversationEndOverlay(
                cancelAction: { activeOverlay = nil },
                confirmAction: {
                    // 확인을 누르면 대화 상태를 정상 마감 처리(showOverlay: false)한 뒤 곧바로 5단계 구슬 수집 모드를 발동
                    finishConversation(showOverlay: false)
                    activeOverlay = nil
                    withAnimation(.easeOut(duration: 0.2)) {
                        isCollecting = true // 5단계 팝업 활성화
                    }
                }
            )
        case .noOrb:
            // 대화 3분이 전부 흘렀으나 분석된 긍정 감정 구슬이 단 하나도 소환되지 않은 경우 뜨는 예외 조치 팝업
            NoOrbOverlay(
                restartAction: restartConversationFlow, // 다시 대화 도전하기 (초기화 후 재기동)
                homeAction: onReturnHome                // 포기하고 홈 스크린으로 이동
            )
        case .none:
            EmptyView()
        default:
            EmptyView()
        }
    }

    // [2단계 핵심 수학 공식] 사용자의 얼굴 중심좌표와 가이드 원의 중심간 기하학적 피타고라스 거리를 활용해 조준 점수 도출
    private func speakerRecognitionScore(for candidate: FaceTrackingCandidate) -> Double {
        let guideCenter = CGPoint(x: 0.5, y: 0.42) // UI 디자인 배치 가이드 중앙 타겟점
        let xDistance = candidate.faceCenter.x - guideCenter.x
        let yDistance = candidate.faceCenter.y - guideCenter.y
        let centerDistance = sqrt(Double(xDistance * xDistance + yDistance * yDistance)) // 유클리드 거리 공식
        let centerScore = max(0, 1 - centerDistance / 0.42) // 중앙에 가깝게 포커싱할수록 비례 점수 획득
        let faceWidth = Double(candidate.faceBounds.width)
        let sizeScore = min(1, max(0, (faceWidth - 0.09) / 0.13)) // 너무 멀거나 너무 가까우면 페널티 감점 가중치 처리
        let detectionBonus = 0.18

        return min(1, detectionBonus + centerScore * 0.52 + sizeScore * 0.30)
    }

    // 2단계 화자 인식이 통과된 경우 비동기 스레드 루프를 열어 3단계 카운트다운을 시작시키는 게이트 함수
    private func startConversationFlowIfNeeded() {
        guard conversationFlowTask == nil, isSpeakerRecognitionReady else { return }

        withAnimation(.easeOut(duration: 0.12)) {
            hasLockedSpeakerRecognition = true // 얼굴 조준 잠금 설정 고정
        }
        conversationFlowTask = Task { @MainActor in
            await startConversationAfterCountdown()
            conversationFlowTask = nil
        }
    }

    // 1단계 공간 인식을 최종 완료 승인하고 바닥 그리드 가이드라인 비활성화 유도
    private func confirmSpaceRecognition() {
        guard planeState == .ready else { return }
        withAnimation(.easeOut(duration: 0.12)) {
            hasConfirmedSpaceRecognition = true
            isPlaneVisualizationVisible = false
        }
    }

    // 2단계 화자 인식을 최종 수동 통과시켜 대화 대기열 비동기 시퀀스에 전달
    private func confirmSpeakerRecognition() {
        if isSpeakerRecognitionReady { startConversationFlowIfNeeded() }
    }

    // -------------------------------------------------------------------------
    // ⏳ [3단계 구현부] 비동기 타이머 기반 루프를 활용해 3초간 카운트다운 진행 및 안내음 연출
    // -------------------------------------------------------------------------
    @MainActor
    private func startConversationAfterCountdown() async {
        guard !isConversationStarted, !hasStartedConversationFlow, !isConversationFinished else { return }

        hasStartedConversationFlow = true
        countdownCuePlayer.speakIntro() // 성우 음성 가이드: "지금부터 대화를 시작합니다."

        // 3초부터 1초까지 정밀 타임 루프를 순회하며 효과음 재생 및 상태 갱신
        for count in stride(from: 3, through: 1, by: -1) {
            countdownValue = count // 화면 중앙에 3, 2, 1 큰 텍스트 변경 반영
            countdownCuePlayer.playTick() // '째깍' 효과음 사운드 재생
            try? await Task.sleep(for: .seconds(1)) // 정밀 1초 대기 비동기 슬립

            if Task.isCancelled { // 도중 뒤로가기 이탈 시 무한 루프 탈출 안전핀
                countdownValue = nil
                hasStartedConversationFlow = false
                return
            }
        }

        countdownValue = nil // 카운트다운 종료 후 텍스트 제거
        isConversationStarted = true // 🛑 [4단계: 대화 진행 페이즈 즉시 On]
        await emotionRuntime.start()   // 실시간 감정 인식 인공지능 분석 가동
        await runConversationTimer()   // 4단계 180초 메인 타이머 태스크로 즉시 바인딩 연쇄 진입
    }

    // -------------------------------------------------------------------------
    // 💬 [4단계 구현부] 180초 실시간 대화 메인 카운트다운 루프 및 실시간 침묵 모니터 시스템
    // -------------------------------------------------------------------------
    @MainActor
    private func runConversationTimer() async {
        remainingConversationSeconds = 180
        secondsWithoutOrb = 0
        trackedOrbEventID = emotionRuntime.latestOrbEvent?.id
        showsPraisePrompt = false

        while remainingConversationSeconds > 0 {
            try? await Task.sleep(for: .seconds(1)) // 1초씩 정밀 대기

            if Task.isCancelled { return } // 이탈 시 스레드 정지

            remainingConversationSeconds -= 1 // 대화 시간 차감
            updatePraisePromptState()          // 침묵 누적 시간 정밀 계산
        }

        // 3분 시간이 모두 소진되어 타임아웃된 경우 평가 함수 가동 (오버레이 팝업 승인 On)
        finishConversation(showOverlay: true)
    }

    // 60초간 대화 감정 구슬이 생성되지 않는 침묵/정체기를 잡아내는 가이드 토스트 분기 함수
    private func updatePraisePromptState() {
        let currentOrbEventID = emotionRuntime.latestOrbEvent?.id
        // 감정이 동화되어 새로운 구슬 ID가 감지되었다면 리셋 처리 후 침묵 탈출
        if let currentOrbEventID, currentOrbEventID != trackedOrbEventID {
            trackedOrbEventID = currentOrbEventID
            secondsWithoutOrb = 0
            showsPraisePrompt = false
            return
        }

        // 변화가 없다면 지속 초 누적
        secondsWithoutOrb += 1
        showsPraisePrompt = secondsWithoutOrb >= 60 // 연속 침묵이 60초에 다다르는 순간 칭찬 권유 토스트 노출
    }

    // -------------------------------------------------------------------------
    // 🚪 [4단계 ➡️ 5단계 브릿지] 대화방 마감 및 구슬 생성 개수 유효성 진단 처리
    // -------------------------------------------------------------------------
    private func finishConversation(showOverlay: Bool) {
        emotionRuntime.stop() // 감정 수집 엔진 안전 정지 (더 이상 새로운 구슬은 생성 안 됨)
        countdownCuePlayer.stop()
        isConversationStarted = false
        isConversationFinished = true
        showsPraisePrompt = false
        countdownValue = nil

        // 타임아웃 종료(`showOverlay: true`)인 경우 생성된 구슬 개수를 확인하여 5단계 진입 유무 판단
        guard showOverlay else { return }
        if emotionRuntime.emittedOrbEventCount == 0 {
            // 대화 도중 소환된 구슬이 0개라면 수집할 매개체가 없으므로 예외 실패 팝업(.noOrb) 실행
            activeOverlay = .noOrb
        } else {
            // 구슬이 1개 이상 안전하게 누적 배치되어 있다면 자연스럽게 5단계 구슬 수집 모드로 즉시 전환
            withAnimation(.easeOut(duration: 0.2)) {
                isCollecting = true // 🛑 [5단계: 구슬 수집 페이즈 발동 On]
            }
        }
    }

    // 실패 혹은 무구슬 상태 팝업에서 다시 대화를 시도할 때 모든 조건 플래그 리사이클링
    private func restartConversationFlow() {
        conversationFlowTask?.cancel()
        conversationFlowTask = nil
        activeOverlay = nil
        isConversationFinished = false
        isCollecting = false
        hasConfirmedSpaceRecognition = true
        isPlaneVisualizationVisible = false
        hasLockedSpeakerRecognition = false
        hasStartedConversationFlow = false
        isConversationStarted = false
        remainingConversationSeconds = 180
        secondsWithoutOrb = 0
        trackedOrbEventID = emotionRuntime.latestOrbEvent?.id
        showsPraisePrompt = false
        startConversationFlowIfNeeded() // 2단계 통과 확인 후 3단계 카운트다운 재시동
    }

    // 왼쪽 상단 뒤로 가기 터치 시 완벽하게 최초 시점인 1단계(공간 인식 바닥 찾기) 상태로 모든 데이터를 공장 초기화
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
        isCollecting = false
        emotionRuntime.stop()
    }
}
