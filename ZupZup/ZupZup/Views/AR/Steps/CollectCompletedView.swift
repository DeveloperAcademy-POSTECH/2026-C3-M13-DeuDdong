//
//  CollectCompletedView.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/7/26.
//


import SwiftUI

struct CollectCompletedView: View {

    let currentOrbCount: Int
    let totalOrbCount: Int

    var body: some View {

        ZStack {

            // MARK: AR Layer

            Color.clear

            // MARK: Top HUD

            VStack(spacing: 16) {

                HStack {

                    ARHomeButtonDark {
                        print("Home")
                    }

                    Spacer()
                }

                Text("구슬 수집 완료")
                    .font(ZZFont.headline)
                    .foregroundStyle(ZZColor.brand400)

                OrbCountCapsule(
                    current: currentOrbCount,
                    total: totalOrbCount,
                    isComplete: true
                )

                Spacer()
            }
            .padding(.top, 78)
            .padding(.horizontal, 16)
            .zIndex(10)

            // MARK: Gradient Overlay

            VStack {

                // 상단 그라데이션

                LinearGradient(
                    colors: [
                        ZZColor.brand400.opacity(0.6),
                        ZZColor.brand400.opacity(0.3),
                        ZZColor.brand400.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)

                Spacer()

                // 하단 그라데이션

                LinearGradient(
                    colors: [
                        ZZColor.brand400.opacity(0.8),
                        ZZColor.brand400.opacity(0.3),
                        ZZColor.brand400.opacity(0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 230)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {

    ZStack {

        Color.gray
            .ignoresSafeArea()

        CollectCompletedView(
            currentOrbCount: 11,
            totalOrbCount: 11
        )
    }
}
