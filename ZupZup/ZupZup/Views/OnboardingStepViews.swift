//
//  OnboardingStepViews.swift
//  Zupzup
//
//  Created by Codex on 6/5/26.
//

import SwiftUI

struct OnboardingStepContentView: View {
    let currentStep: OnboardingStep
    @Binding var currentCardIndex: Int
    let permissionManager: OnboardingPermissionManager
    var openSettingsAction: () -> Void

    var body: some View {
        switch currentStep {
        case .serviceFlow:
            OnboardingServiceFlowStepView(currentCardIndex: $currentCardIndex)
        case .orbDescription:
            OnboardingOrbDescriptionStepView()
        case .permissions:
            ScrollView(showsIndicators: false) {
                OnboardingPermissionStepView(
                    permissionManager: permissionManager,
                    openSettingsAction: openSettingsAction
                )
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct OnboardingServiceFlowStepView: View {
    static let finalCardIndex = 3

    @Binding var currentCardIndex: Int

    var body: some View {
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
                    }.tag(Self.finalCardIndex)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 465)

                HStack(spacing: 8) {
                    ForEach(0...Self.finalCardIndex, id: \.self) { index in
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
}

struct OnboardingOrbDescriptionStepView: View {
    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(title: "구슬은 대화 속 긍정 표현을\n기반으로 생성 됩니다")
                .padding(.bottom, 24)

            VStack(spacing: 4) {
                ForEach(EmotionType.allCases) { type in
                    EmotionRow(type: type)
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
            .frame(maxHeight: 460)
        }
    }
}

struct OnboardingPermissionStepView: View {
    let permissionManager: OnboardingPermissionManager
    var openSettingsAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(title: "실제 공간에서 사용하기 위한\n권한 허용이 필요합니다")
                .padding(.bottom, 24)

            VStack(spacing: 24) {
                PermissionSectionView(title: "필수적 접근 권한", cards: requiredPermissionCards)

                Divider()
                    .padding(.horizontal, 4)

                PermissionSectionView(title: "선택적 접근 권한", cards: optionalPermissionCards)
            }
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
                Button(action: openSettingsAction) {
                    Text("설정에서 권한 허용하기")
                        .font(ZZFont.caption)
                        .foregroundStyle(ZZColor.brand400)
                        .padding(.top, 8)
                }
            }
        }
    }

    private var requiredPermissionCards: [PermissionCardData] {
        [
            PermissionCardData(
                systemName: "camera.fill",
                title: "카메라",
                description: "AR 환경에서 공간을 인식하고,구슬을 환경 위에 쌓기 위한 권한"
            ),
            PermissionCardData(
                systemName: "mic.fill",
                title: "마이크·음성 인식",
                description: "대화를 텍스트로 변환해 긍정 표현을 분류하기 위한 권한"
            )
        ]
    }

    private var optionalPermissionCards: [PermissionCardData] {
        [
            PermissionCardData(
                systemName: "photo.on.rectangle.angled",
                title: "사진",
                description: "AR 인증샷을 저장하기 위한 권한"
            )
        ]
    }
}

struct OnboardingTopProgressBar: View {
    let currentStep: OnboardingStep

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ZZColor.gray2)
                        .frame(height: 6)

                    Capsule()
                        .fill(ZZColor.brand400)
                        .frame(width: geo.size.width * currentStep.progress, height: 6)
                        .animation(.spring(), value: currentStep)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, ZZSpacing.screenHorizontal)
        }
    }
}
