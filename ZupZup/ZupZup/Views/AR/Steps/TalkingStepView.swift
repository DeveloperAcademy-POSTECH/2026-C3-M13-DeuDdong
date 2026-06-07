//
//  AR_Talking.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/5/26.
//

import SwiftUI

struct ARTalkingView: View {

    let onFinished: () -> Void

    @State private var count = 3
    @State private var isConversationStarted = false

    @State private var remainingSeconds = 180

    @State private var showHomeExitOverlay = false
    @State private var showConversationEndOverlay = false

    var body: some View {

        ZStack {

            // 실제 AR 연결 시 이 자리에 AR View가 들어옴
            Color.clear

            if isConversationStarted {

                conversationView

            } else {

                countdownView
            }

            // MARK: Overlay Layer

            if showHomeExitOverlay {

                HomeExitOverlay(

                    cancelAction: {
                        showHomeExitOverlay = false
                    },

                    confirmAction: {
                        print("Go Home")
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }

            if showConversationEndOverlay {

                ConversationEndOverlay(

                    cancelAction: {
                        showConversationEndOverlay = false
                    },

                    confirmAction: {
                        print("End Conversation")
                    }
                )
                .transition(.opacity)
                .zIndex(101)
            }
        }
        .ignoresSafeArea()
        .task {
            await startCountdown()
        }
    }
}

// MARK: - Countdown

extension ARTalkingView {

    private var countdownView: some View {

        ZStack {

            CountdownOverlay(count: count)

            VStack {

                HStack {

                    ARBackButtonDark {
                        print("Back")
                    }

                    Spacer()
                }

                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 78)
        }
    }

    private func startCountdown() async {

        while count > 1 {

            try? await Task.sleep(
                for: .seconds(1)
            )

            await MainActor.run {

                withAnimation(.easeInOut(duration: 0.25)) {
                    count -= 1
                }
            }
        }

        try? await Task.sleep(
            for: .seconds(1)
        )

        await MainActor.run {

            withAnimation {
                isConversationStarted = true
            }
        }

        await startConversationTimer()
    }
}

// MARK: - Conversation

extension ARTalkingView {

    private var conversationView: some View {

        ZStack {

            VStack {

                Spacer()

                // VoiceWaveformView 여기에 음파를 넣어주세요!

                Spacer()
                    .frame(height: 30)
            }

            // MARK: Top HUD

            VStack {

                ZStack {

                    // 중앙 타이머
                    ConversationTimerView(
                        remainingSeconds: remainingSeconds
                    )

                    // 좌우 버튼
                    HStack {

                        ARHomeButtonDark {

                            withAnimation {
                                showHomeExitOverlay = true
                            }
                        }

                        Spacer()

                        Button {

                            withAnimation {
                                showConversationEndOverlay = true
                            }

                        } label: {

                            Text("대화 종료")
                                .font(ZZFont.body)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
            .padding(.top, 78)
        }
    }

    private func startConversationTimer() async {

        while remainingSeconds > 0 {

            try? await Task.sleep(
                for: .seconds(1)
            )

            await MainActor.run {
                remainingSeconds -= 1
            }
        }

        await MainActor.run {
            onFinished()
        }
    }
}

// MARK: - Preview

#Preview {

    ZStack {

        Color.black
            .ignoresSafeArea()

        ARTalkingView {

        }
    }
}
