//
//  OnboardingBottomBar.swift
//  Zupzup
//
//  Created by Codex on 6/5/26.
//

import SwiftUI

struct OnboardingBottomBar: View {
    let currentStep: OnboardingStep
    let serviceFlowIsComplete: Bool
    let permissionButtonTitle: String
    let permissionIsRequesting: Bool
    var previousAction: () -> Void
    var primaryAction: () -> Void

    var body: some View {
        Group {
            if currentStep == .serviceFlow {
                PrimaryButton(title: "다음", isEnabled: serviceFlowIsComplete, action: primaryAction)
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
            } else {
                HStack(spacing: 4) {
                    Button(action: previousAction) {
                        Text("이전")
                            .font(ZZFont.body)
                            .foregroundStyle(ZZColor.gray6)
                            .frame(width: 112, height: ZZSpacing.bottomButtonHeight)
                            .background(ZZColor.gray3)
                            .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                    }

                    Button(action: primaryAction) {
                        Text(primaryButtonTitle)
                            .font(ZZFont.body)
                            .foregroundStyle(.white)
                            .frame(width: 250, height: ZZSpacing.bottomButtonHeight)
                            .background(primaryButtonColor)
                            .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                    }
                    .disabled(primaryButtonDisabled)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 12)
    }

    private var primaryButtonTitle: String {
        currentStep == .permissions ? permissionButtonTitle : "다음"
    }

    private var primaryButtonColor: Color {
        permissionIsRequesting ? ZZColor.gray4 : ZZColor.brand400
    }

    private var primaryButtonDisabled: Bool {
        currentStep == .permissions && permissionIsRequesting
    }
}
