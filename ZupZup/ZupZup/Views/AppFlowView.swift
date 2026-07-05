//
//  AppFlowView.swift
//  ZupZup
//
//  Created by Simon on 6/4/26.
//

import SwiftUI

struct AppFlowView: View {
    @State private var currentScreen: AppScreen = .splash
    @State private var reportCollectedCount = 0
    @State private var reportSummary = ReportSummary()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = false

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView {
                    currentScreen = isFirstLaunch ? .home : .onboarding
                }
            case .onboarding:
                OnboardingView {
                    isFirstLaunch = true
                    currentScreen = .home
                }
            case .home:
                HomeView(
                    onStartConversation: {
                        currentScreen = .conversation
                    },
                    onShowRandomReport: {
                        #if DEBUG
                        reportSummary = ReportSummary.previewSamples.randomElement() ?? .preview
                        currentScreen = .report
                        #endif
                    }
                )
            case .conversation:
                conversationView
            case .report:
                ReportView(
                    onHome: {
                        currentScreen = .home
                    },
                    summary: reportSummary
                )
            }
        }
        .animation(.easeInOut(duration: 0.22), value: currentScreen)
    }

    private var conversationView: some View {
        ZStack(alignment: .topTrailing) {
            ARSceneView(
                onFinishConversation: { summary in
                    reportSummary = summary
                    currentScreen = .report
                },
                onReturnHome: { currentScreen = .home }
            )
        }
    }
}

#Preview {
    AppFlowView()
}
