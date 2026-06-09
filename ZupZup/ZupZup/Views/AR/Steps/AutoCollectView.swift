//
//  AutoCollectView.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/8/26.
//

import SwiftUI

struct AutoCollectView: View {

    @State private var showHomeExitOverlay = false
    

    let onCompleted: () -> Void

    var body: some View {

        ZStack {

            // MARK: AR Layer

            Color.clear

            // MARK: Top HUD

            VStack(spacing: 16) {

                HStack {

                    ARHomeButtonDark {
                        showHomeExitOverlay = true
                    }

                    Spacer()
                }

                Text("자동 수집 중")
                    .font(ZZFont.headline)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.top, 78)
            .padding(.horizontal, 16)

            // MARK: Gradient Overlay

            VStack {

                // 상단 그라데이션

                LinearGradient(
                    colors: [
                        ZZColor.gray9.opacity(0.8),
                        ZZColor.gray9.opacity(0.5),
                        ZZColor.gray9.opacity(0.2),
                        ZZColor.gray0.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)

                Spacer()

                // 하단 그라데이션

                LinearGradient(
                    colors: [
                        ZZColor.gray9,
                        ZZColor.gray9.opacity(0.8),
                        ZZColor.gray9.opacity(0.3),
                        ZZColor.gray0.opacity(0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 330)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // MARK: Home Exit Overlay

            if showHomeExitOverlay {

                HomeExitOverlay(

                    cancelAction: {
                        showHomeExitOverlay = false
                    },

                    confirmAction: {
                        print("Go Home")
                    }
                )
                .zIndex(999)
            }
        }
        .ignoresSafeArea()

        // MARK: Auto Complete

        .onAppear {

            Task {

                try? await Task.sleep(for: .seconds(3))

                await MainActor.run {
                    onCompleted()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {

    ZStack {

        Color.gray
            .ignoresSafeArea()

        AutoCollectView {

        }
    }
}
