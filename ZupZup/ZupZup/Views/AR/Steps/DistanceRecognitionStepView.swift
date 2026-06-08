//
//  AR_Ready_2.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/5/26.
//

import SwiftUI

struct DistanceRecognitionStepView: View {

    private let guideSize: CGFloat = 280
    var progress: Double = 0
    var isReady = false
    var showsPreviewBackground = true
    var backAction: () -> Void = {}
    var nextAction: () -> Void = {}

    var body: some View {

        GeometryReader { geometry in

            let centerY = geometry.size.height * 0.42

            ZStack {

                // MARK: 전체 화면 오버레이

                ZStack {

                    if showsPreviewBackground {
                        Color.gray
                    }

                    ZZColor.gray9.opacity(0.8)

                    Circle()
                        .frame(
                            width: guideSize,
                            height: guideSize
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: centerY
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .ignoresSafeArea()

                // MARK: Face Guide Ring

                FaceGuideRing(
                    progress: progress,
                    size: 300
                )
                .position(
                    x: geometry.size.width / 2,
                    y: centerY
                )

                // MARK: Back Button

                VStack {
                    HStack {
                        ARBackButtonLight(action: backAction)
                        Spacer()
                    }

                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 78)

                // MARK: Title

                VStack {
                    Text("상대와의 거리 인식")
                        .font(ZZFont.title)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.top, 165)

                // MARK: Instruction

                VStack {

                    Spacer()

                    Text(isReady ? "상대 인식이 완료되었습니다" : "상대의 얼굴을\n원 안에 맞춰주세요")
                        .font(ZZFont.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)

                    PrimaryButton(
                        title: "다음",
                        isEnabled: isReady,
                        action: nextAction
                    )
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
                    .padding(.bottom, 54)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DistanceRecognitionStepView()
}
