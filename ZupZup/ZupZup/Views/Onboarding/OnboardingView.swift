//
//  OnboardingView.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI
internal import UIKit

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var currentStep: OnboardingStep = .serviceFlow
    @State private var currentCardIndex: Int = 0
    @State private var permissionManager = OnboardingPermissionManager()

    var body: some View {
        ZStack {
            ZZColor.gray0.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingTopProgressBar(currentStep: currentStep)
                    .padding(.top, 20)

                OnboardingStepContentView(
                    currentStep: currentStep,
                    currentCardIndex: $currentCardIndex,
                    permissionManager: permissionManager,
                    openSettingsAction: openAppSettings
                )
                    .padding(.top, 40)

                Spacer()

                OnboardingBottomBar(
                    currentStep: currentStep,
                    serviceFlowIsComplete: currentCardIndex == OnboardingServiceFlowStepView.finalCardIndex,
                    permissionButtonTitle: permissionManager.primaryButtonTitle,
                    permissionIsRequesting: permissionManager.isRequesting,
                    previousAction: moveToPreviousStep,
                    primaryAction: handlePrimaryAction
                )
            }
        }
        .onAppear {
            permissionManager.refreshStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshStatuses()
        }
    }

    private func handlePrimaryAction() {
        if currentStep == .permissions {
            Task {
                await handlePermissionPrimaryAction()
            }
            return
        }

        guard let nextStep = currentStep.next else {
            return
        }

        withAnimation {
            currentStep = nextStep
        }
    }

    private func moveToPreviousStep() {
        guard let previousStep = currentStep.previous else {
            return
        }

        withAnimation {
            currentStep = previousStep
        }
    }

    @MainActor
    private func handlePermissionPrimaryAction() async {
        if permissionManager.hasRequiredPermissions {
            onFinished()
            return
        }

        if await permissionManager.requestPermissions() {
            onFinished()
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
