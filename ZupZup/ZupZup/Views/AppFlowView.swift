//
//  AppFlowView.swift
//  ZupZup
//
//  Created by Simon on 6/4/26.
//

import SwiftUI

struct AppFlowView: View {
    @State private var currentScreen: AppScreen = .splash

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView {
                    currentScreen = .onboarding
                }
            case .onboarding:
                OnboardingView {
                    currentScreen = .home
                }
            case .home:
                HomeView {
                    currentScreen = .conversation
                }
            case .conversation:
                conversationView
            case .report:
                ReportView(
                    onSave: { currentScreen = .home },
                    onCertify: { currentScreen = .certification }
                )
            case .certification:
                CertificationView {
                    currentScreen = .report
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: currentScreen)
    }

    private var conversationView: some View {
        ZStack(alignment: .topTrailing) {
            ARSceneView()

            Button {
                currentScreen = .report
            } label: {
                Text("종료하기")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ZZColor.gray9)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.regularMaterial, in: Capsule())
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }
}

#Preview {
    AppFlowView()
}
