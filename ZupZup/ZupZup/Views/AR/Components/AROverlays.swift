//
//  AROverlayView.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/7/26.
//

//
//  AROverlays.swift
//  ZupZup
//

import SwiftUI

// MARK: - Overlay Type

enum AROverlayType {
    case homeExit
    case conversationEnd
    case noOrb
    case autoCollect
    case collectionComplete
}

// MARK: - Common Background

struct ARDimmedOverlay<Content: View>: View {

    @ViewBuilder
    let content: Content

    var body: some View {

        ZStack {

            ZZColor.gray9
                .opacity(0.8)
                .ignoresSafeArea()

            content
        }
    }
}

// MARK: - Home Exit

struct HomeExitOverlay: View {

    let cancelAction: () -> Void
    let confirmAction: () -> Void

    var body: some View {

        ARDimmedOverlay {

            ZStack {

                VStack(spacing: 12) {

                    Text("홈으로 나가시겠습니까?")
                        .font(ZZFont.headline)
                        .foregroundStyle(.white)

                    Text("지금까지의 내용은 저장되지 않습니다")
                        .font(ZZFont.body)
                        .foregroundStyle(.white)
                    
                }.padding(.bottom, 250)

                VStack {

                    Spacer()

                    HStack(spacing: 8) {

                        SecondaryButton(
                            title: "취소하기",
                            action: cancelAction
                        )
                        .frame(width: 112)

                        PrimaryButton(
                            title: "홈으로 나가기",
                            action: confirmAction
                        )
                        .frame(width: 250)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 50)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Conversation End

struct ConversationEndOverlay: View {

    let cancelAction: () -> Void
    let confirmAction: () -> Void

    var body: some View {

        ARDimmedOverlay {

            ZStack {

                VStack(spacing: 12) {

                    Text("대화를 종료하시겠습니까?")
                        .font(ZZFont.headline)
                        .foregroundStyle(.white)

                    Text("구슬 수집 단계로 넘어갑니다")
                        .font(ZZFont.body)
                        .foregroundStyle(.white)
                }.padding(.bottom, 250)

                VStack {

                    Spacer()

                    HStack(spacing: 8) {

                        SecondaryButton(
                            title: "취소하기",
                            action: cancelAction
                        )
                        .frame(width: 112)

                        PrimaryButton(
                            title: "대화 종료하기",
                            action: confirmAction
                        )
                        .frame(width: 250)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 50)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - No Orb

struct NoOrbOverlay: View {

    let restartAction: () -> Void
    let homeAction: () -> Void

    var body: some View {

        ARDimmedOverlay {

            ZStack {

                VStack(spacing: 8) {

                    Text("대화가 종료되었습니다")
                        .font(ZZFont.headline)
                        .foregroundStyle(.white)

                    Text("수집할 구슬이 없습니다")
                        .font(ZZFont.title)
                        .foregroundStyle(.white)

                    Text("새로운 대화로 구슬을 수집해 보세요")
                        .font(ZZFont.body)
                        .foregroundStyle(.white)
                        .padding(.top, 12)
                }.padding(.bottom, 250)

                VStack {

                    Spacer()

                    VStack(spacing: 12) {

                        PrimaryButton(
                            title: "다시 시작하기",
                            action: restartAction
                        )

                        SecondaryButton(
                            title: "홈으로 돌아가기",
                            action: homeAction
                        )
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Auto Collect

struct AutoCollectOverlay: View {

    let cancelAction: () -> Void
    let completeAction: () -> Void

    @State private var remainingSeconds = 5

    var body: some View {

        ARDimmedOverlay {

            ZStack {

                VStack(spacing: 12) {

                    Text("수집이 1분간 이루어지지 않아")
                        .font(ZZFont.headline)
                        .foregroundStyle(.white)

                    Text("자동 수집을 수행합니다")
                        .font(ZZFont.title)
                        .foregroundStyle(.white)

                    Text("\(remainingSeconds)초 뒤 시작")
                        .font(ZZFont.body)
                        .foregroundStyle(.white)
                }.padding(.bottom, 250)

                VStack {

                    Spacer()

                    SecondaryButton(
                        title: "취소하기",
                        action: cancelAction
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .task {
            await startCountdown()
        }
    }

    private func startCountdown() async {

        while remainingSeconds > 1 {

            try? await Task.sleep(
                for: .seconds(1)
            )

            await MainActor.run {
                remainingSeconds -= 1
            }
        }

        try? await Task.sleep(
            for: .seconds(1)
        )

        await MainActor.run {
            completeAction()
        }
    }
}

// MARK: - Collection Complete

struct CollectionCompleteOverlay: View {

    let reportAction: () -> Void

    var body: some View {

        ARDimmedOverlay {

            ZStack {

                VStack(spacing: 12) {

                    Text("구슬 수집 완료")
                        .font(ZZFont.title)
                        .foregroundStyle(.white)

                    Text("자세한 수집 결과를 확인하세요")
                        .font(ZZFont.body)
                        .foregroundStyle(.white)
                        .padding(.bottom, 30)

                    Image("FullBallGlass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .padding(.top, 12)
                        .padding(.bottom, 70)
                }

                VStack {

                    Spacer()

                    PrimaryButton(
                        title: "리포트 확인하기",
                        action: reportAction
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Preview

#Preview("Home Exit") {
    HomeExitOverlay(
        cancelAction: {},
        confirmAction: {}
    )
}

#Preview("Conversation End") {
    ConversationEndOverlay(
        cancelAction: {},
        confirmAction: {}
    )
}

#Preview("No Orb") {
    NoOrbOverlay(
        restartAction: {},
        homeAction: {}
    )
}

#Preview("Auto Collect") {
    AutoCollectOverlay(
            cancelAction: {},
            completeAction: {
                print("Auto Collect Start")
            }
    )
}

#Preview("Collection Complete") {
    CollectionCompleteOverlay(
        reportAction: {}
    )
}
