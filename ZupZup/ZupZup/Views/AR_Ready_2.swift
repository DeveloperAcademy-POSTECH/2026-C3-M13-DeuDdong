//
//  AR_Ready_2.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/5/26.
//

import SwiftUI

struct DistanceRecognitionStepView: View {

    var body: some View {

        ZStack {

            // MARK: Preview용 AR 배경

            Color.gray
                .ignoresSafeArea()

            // MARK: 어두운 오버레이

            HoleOverlay()

            VStack {

                // MARK: 상단

                HStack {

                    ARBackButton_light {
                        print("Back")
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // MARK: 제목

                Text("상대와의 거리 인식")
                    .font(ZZFont.headline)
                    .foregroundStyle(.white)

                Spacer()

                // MARK: 얼굴 가이드

                ZStack {

                    Circle()
                        .fill(.clear)
                        .frame(width: 280, height: 280)

                    FaceGuideRing(progress: 1.0)
                }

                Spacer()

                // MARK: 안내문

                Text("상대의 얼굴을\n원 안에 맞춰주세요")
                    .font(ZZFont.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: 120)
            }
        }
    }
}


struct HoleOverlay: View {

    var body: some View {

        GeometryReader { geo in

            ZStack {

                Color.black.opacity(0.55)

                Circle()
                    .frame(width: 280, height: 280)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
    }
}


#Preview {
    DistanceRecognitionStepView()
}
