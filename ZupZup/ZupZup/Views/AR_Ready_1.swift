//
//  SpaceRecognitionStepView.swift
//  ZupZup
//

import SwiftUI

struct SpaceRecognitionStepView: View {

    @State private var moveRight = false

    var body: some View {

        ZStack {

            VStack {

                // MARK: 상단 영역

                HStack {
                    ARBackButton_black {
                        print("Back")
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 79)

                Spacer()
            }

            // MARK: 하단 HUD 영역

            VStack {

                Spacer()

                ZStack {

                    // 그라디언트
                    LinearGradient(
                        colors: [
                            ZZColor.gray9,
                            ZZColor.gray9.opacity(0.8),
                            ZZColor.gray9.opacity(0.3),
                            ZZColor.gray0.opacity(0.0)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )

                    VStack(spacing: 16) {

                        Spacer()

                        // MARK: 스캔 애니메이션

                        ZStack {

                            Image("floor_guide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240)

                            Image("phone_guide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                                .offset(
                                    x: moveRight ? 80 : -80,
                                    y: 35
                                )
                                .rotationEffect(
                                    .degrees(moveRight ? 8 : -8)
                                )
                                .animation(
                                    .easeInOut(duration: 1.4)
                                        .repeatForever(autoreverses: true),
                                    value: moveRight
                                )
                        }

                        // MARK: 안내 문구

                        Spacer()
                        Text("격자 무늬가 나올 때까지\n바닥을 바라봐주세요")
                            .font(ZZFont.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
                .frame(height: 330)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            moveRight = true
        }
    }
}

#Preview {
    SpaceRecognitionStepView()
}
