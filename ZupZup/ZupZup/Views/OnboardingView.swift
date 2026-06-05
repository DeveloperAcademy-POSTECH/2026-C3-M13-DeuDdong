//
//  OnboardingView.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    var onFinished: () -> Void

    // 온보딩 단계 제어 상태 (1: 서비스 플로우, 2: 구슬 설명, 3: 권한 허용)
    @State private var currentStep: Int = 1
    @State private var currentCardIndex: Int = 0
    @State private var permissionManager = OnboardingPermissionManager()

    var body: some View {
        ZStack {
            ZZColor.gray0.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingTopProgressBar(currentStep: currentStep)
                    .padding(.top, 20)

                onboardingStepContent
                    .padding(.top, 40)

                Spacer()

                // 하단 버튼 바: 규격 고정 및 디바이스 대응을 위해 분기 처리
                Group {
                    if currentStep == 1 {
                        PrimaryButton(title: "다음", isEnabled: currentCardIndex == 3) {
                            withAnimation { currentStep = 2 }
                        }
                        .padding(.horizontal, ZZSpacing.screenHorizontal)

                    } else if currentStep == 2 {
                        HStack(spacing: 4) {
                            Button(
                                action: {
                                    withAnimation { currentStep = 1 }
                                },
                                label: {
                                    Text("이전")
                                        .font(ZZFont.body)
                                        .foregroundStyle(ZZColor.gray6)
                                        .frame(width: 112, height: ZZSpacing.bottomButtonHeight)
                                        .background(ZZColor.gray3)
                                        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                                }
                            )

                            Button(
                                action: {
                                    withAnimation { currentStep = 3 }
                                },
                                label: {
                                    Text("다음")
                                        .font(ZZFont.body)
                                        .foregroundStyle(.white)
                                        .frame(width: 250, height: ZZSpacing.bottomButtonHeight)
                                        .background(ZZColor.brand400)
                                        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)

                    } else {
                        HStack(spacing: 4) {
                            Button(
                                action: {
                                    withAnimation { currentStep = 2 }
                                },
                                label: {
                                    Text("이전")
                                        .font(ZZFont.body)
                                        .foregroundStyle(ZZColor.gray6)
                                        .frame(width: 112, height: ZZSpacing.bottomButtonHeight)
                                        .background(ZZColor.gray3)
                                        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                                }
                            )

                            Button(
                                action: {
                                    Task {
                                        await handlePermissionPrimaryAction()
                                    }
                                },
                                label: {
                                    Text(permissionManager.primaryButtonTitle)
                                        .font(ZZFont.body)
                                        .foregroundStyle(.white)
                                        .frame(width: 250, height: ZZSpacing.bottomButtonHeight)
                                        .background(permissionManager.isRequesting ? ZZColor.gray4 : ZZColor.brand400)
                                        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                                }
                            )
                            .disabled(permissionManager.isRequesting)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    @ViewBuilder
    private var onboardingStepContent: some View {
        switch currentStep {
        case 1:
            step1ServiceFlowView
        case 2:
            step2OrbDescriptionView
        case 3:
            ScrollView(showsIndicators: false) {
                step3PermissionView
                    .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        default:
            EmptyView()
        }
    }

    // MARK: - Step 1: 서비스 전체 플로우 설명
    private var step1ServiceFlowView: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(title: "대화 속 긍정의 말을 모아\n나의 구슬들을 모아보세요")

            ZStack(alignment: .bottom) {
                TabView(selection: $currentCardIndex) {
                    OnboardingCardView(title: "상대와 대화", description: "카메라로 상대를 비추며\n대화를 진행합니다") {
                        Image("img_onboarding_tip1").resizable().scaledToFit()
                    }.tag(0)

                    OnboardingCardView(title: "긍정 표현 감지", description: "칭찬, 응원, 감사 등의\n긍정적인 말이 감지됩니다") {
                        Image("img_onboarding_tip2").resizable().scaledToFit()
                    }.tag(1)

                    OnboardingCardView(title: "구슬 생성", description: "긍정 표현은 감정 구슬로\n변환되어 공간에 쌓입니다") {
                        Image("img_onboarding_tip3").resizable().scaledToFit()
                    }.tag(2)

                    OnboardingCardView(title: "구슬 수집", description: "대화가 끝난 뒤 구슬을\n직접 모아볼 수 있습니다") {
                        Image("img_onboarding_tip4").resizable().scaledToFit()
                    }.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // 카드 실제 콘텐츠 높이에 맞춰 하단 빈 공간을 제거하기 위해 465 고정
                .frame(height: 465)

                // 페이지 인디케이터: 카드 최하단 텍스트 기준 간격 조정을 위한 오프셋
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(currentCardIndex == index ? ZZColor.brand400 : ZZColor.gray3)
                            .frame(width: 8, height: 8)
                    }
                }
                .offset(y: 20)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Step 2: 구슬 종류 설명
    private var step2OrbDescriptionView: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(title: "구슬은 대화 속 긍정 표현을\n기반으로 생성 됩니다")
                .padding(.bottom, 24)

                VStack(spacing: 4) {
                    ForEach(EmotionType.allCases) { type in
                        EmotionRow(type: type)
                            // 배경 분리 및 스펙 고정 (가로 300, 세로 81, 셀 간격 vertical 3)
                            .background(
                                RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            )
                            .frame(width: 300, height: 81)
                            .padding(.vertical, 3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxHeight: 460) // 5개 리스트가 안전하게 들어오도록 제한한 최대 높이
        }
    }

    // MARK: - Step 3: 앱 사용 권한 설명
    private var step3PermissionView: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(title: "실제 공간에서 사용하기 위한\n권한 허용이 필요합니다")
                .padding(.bottom, 24)

            VStack(spacing: 24) {
                PermissionSectionView(
                    title: "필수적 접근 권한",
                    cards: [
                        PermissionCardData(
                            systemName: "camera.fill",
                            title: "카메라",
                            description: "AR 환경에서 공간을 인식하고,\n구슬을 환경 위에 쌓기 위한 권한"
                        ),
                        PermissionCardData(
                            systemName: "mic.fill",
                            title: "마이크·음성 인식",
                            description: "대화를 텍스트로 변환해\n긍정 표현을 분류하기 위한 권한"
                        )
                    ]
                )

                Divider()
                    .padding(.horizontal, 4)

                PermissionSectionView(
                    title: "선택적 접근 권한",
                    cards: [
                        PermissionCardData(
                            systemName: "photo.on.rectangle.angled",
                            title: "사진",
                            description: "AR 인증샷을 저장하기 위한 권한"
                        )
                    ]
                )
            }
            // 디자인 시스템 300 규격 통일을 위해 기존 screenHorizontal 패딩 대신 고정 가로폭 적용
            // .padding(.horizontal, ZZSpacing.screenHorizontal)
            .frame(width: 300)

            if !permissionManager.message.isEmpty {
                Text(permissionManager.message)
                    .font(ZZFont.caption)
                    .foregroundStyle(permissionManager.shouldShowSettingsButton ? ZZColor.brand500 : ZZColor.gray6)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(width: 300)
                    .padding(.top, 18)
            }

            if permissionManager.shouldShowSettingsButton {
                Button(
                    action: openAppSettings,
                    label: {
                        Text("설정에서 권한 허용하기")
                            .font(ZZFont.caption)
                            .foregroundStyle(ZZColor.brand400)
                            .padding(.top, 8)
                    }
                )
            }
        }
    }

    @MainActor
    private func handlePermissionPrimaryAction() async {
        if permissionManager.hasRequiredPermissions {
            onFinished()
            return
        }

        if await permissionManager.requestPermissions() {
            onFinished()
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Progress Bar
struct OnboardingTopProgressBar: View {
    let currentStep: Int

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ZZColor.gray2)
                        .frame(height: 6)

                    Capsule()
                        .fill(ZZColor.brand400)
                        .frame(width: geo.size.width * (CGFloat(currentStep) / 3.0), height: 6)
                        .animation(.spring(), value: currentStep)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, ZZSpacing.screenHorizontal)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
