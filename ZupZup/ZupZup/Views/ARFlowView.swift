import SwiftUI

struct ARFlowView: View {
    var onFlowCompleted: () -> Void

    // 프리뷰 검수용 서브 상태 기계 구현
    @State private var currentStep: String = "dialog" // space, distance, dialog, collection, alertPopup
    @State private var showAutoAlertPopup: Bool = true

    var body: some View {
        ZStack {
            // 카메라 월드 백그라운드를 모사하는 UI 검수용 다크 배경 시트
            Color.black.opacity(0.75).ignoresSafeArea()

            // --- 각 기획 세부 화면 단계별 UI 오버레이 교체 레이어 --
            switch currentStep {
            case "space":
                // 3.0.pdf / 3.1.pdf 기기 바닥 격자 인식 단계
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "camera.metering.matrix")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.5))

                    ARInstructionText(text: "격자 무늬가 나올 때까지\n바닥을 바라봐주세요")
                    Spacer()
                }

            case "distance":
                // 4.0.pdf ~ 4.2.pdf 상대방 원형 가이드 피팅 단계
                ZStack {
                    FaceGuideRing(progress: 0.6)
                        .frame(width: 220, height: 220)

                    VStack {
                        Text("상대와의 거리 인식")
                            .font(ZZFont.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 80)

                        Spacer()

                        ARInstructionText(text: "상대의 얼굴을\n원 안에 맞춰주세요")
                            .padding(.bottom, 120)
                    }
                }

            case "dialog":
                // 6.1.pdf ~ 6.3.pdf 실시간 자막 대화 레이어 HUD
                ZStack {
                    // 중앙 하단 실시간 감지 공간 자막 (6.1.pdf)
                    VStack {
                        Spacer()
                        Text("“항상 열심히 준비해줘서 정말 고마워”")
                            .font(ZZFont.body)
                            .foregroundStyle(ZZColor.emotionBlue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 220)
                    }

                    // 컨트롤러 요소 탑다운 배치
                    VStack(spacing: 0) {
                        HStack {
                            ARBackButton { currentStep = "space" }
                            Spacer()
                            ConversationTimerView(remainingSeconds: 131) // 시안의 02:11 하드코딩 매칭
                            Spacer()
                            ARHelpButton {}
                        }
                        .padding(.horizontal, ZZSpacing.screenHorizontal)
                        .padding(.top, 16)

                        Spacer()

                        // 하단 마이크 감지 파형 및 토스트 경고 바 조합 (6.2.pdf)
                        VoiceWaveformView(samples: [0.3, 0.6, 0.2, 0.9, 0.4, 0.7, 0.3, 0.5])
                            .padding(.bottom, 16)

                        StatusToast(text: "조금 더 크게 대화 해주세요", systemName: "speaker.wave.2.fill", isWarning: false)
                            .padding(.bottom, 20)

                        PrimaryButton(title: "대화 종료") {
                            currentStep = "collection"
                        }
                        .padding(.horizontal, ZZSpacing.screenHorizontal)
                        .padding(.bottom, 34)
                    }
                }

            case "collection":
                // 8.2.pdf ~ 8.3.pdf 손가락 드래그 수집 단계 HUD
                ZStack {
                    VStack(spacing: 0) {
                        HStack {
                            ARBackButton { currentStep = "dialog" }
                            Spacer()
                            OrbCountCapsule(current: 5, total: 11, isComplete: false) // 시안 속 5/11 구현
                            Spacer()
                            ARHelpButton {}
                        }
                        .padding(.horizontal, ZZSpacing.screenHorizontal)
                        .padding(.top, 16)

                        Spacer()

                        AutoCollectButton {
                            // 자동 수집 완료 액션 모사 시 리포트로 통과
                            onFlowCompleted()
                        }
                        .padding(.bottom, 34)
                    }

                    // 8.3.pdf 타임아웃 경고 전체 모달 오버레이 조합 확인
                    if showAutoAlertPopup {
                        TimeoutNoticeOverlay(
                            title: "수집이 1분간 이루어지지 않아\n자동 수집을 수행합니다",
                            subtitle: "5초 뒤 시작",
                            cancelAction: { showAutoAlertPopup = false }
                        )
                    }
                }

            case "alertPopup":
                // 7.1.pdf 기획계의 대표 모달 다이어로그를 독립 검수할 수 있는 레이아웃 플레이스
                TimeoutNoticeOverlay(
                    title: "대화를 종료하시겠습니까?",
                    subtitle: "구슬 수집 단계로 넘어갑니다",
                    cancelAction: { currentStep = "dialog" }
                )

            default:
                EmptyView()
            }

            // --- 최상단 프리뷰용 제어 스위치 바 (실제 출시 앱에는 안 보이고 개발 캔버스용) ---
            VStack {
                HStack(spacing: 4) {
                    Group {
                        Button("공간") { currentStep = "space" }
                        Button("거리") { currentStep = "distance" }
                        Button("대화") { currentStep = "dialog" }
                        Button("수집") { currentStep = "collection"; showAutoAlertPopup = true }
                        Button("종료팝업") { currentStep = "alertPopup" }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
                .padding(.top, 70)
                Spacer()
            }
        }
    }
}

#Preview {
    ARFlowView(onFlowCompleted: {})
}
