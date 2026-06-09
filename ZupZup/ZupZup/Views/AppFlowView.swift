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
                    onSave: {
                        currentScreen = .home
                    },
                    onCertify: {
                        currentScreen = .certification
                    },
                    onHome: {
                        currentScreen = .home
                    }
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
            ARSceneView(
                onFinishConversation: { currentScreen = .report },
                onReturnHome: { currentScreen = .home }
            )
        }
    }
}

#Preview {
    AppFlowView()
}
