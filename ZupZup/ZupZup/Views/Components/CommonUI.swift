//
//  CommonUI.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI
internal import UIKit

private struct IdleTimerModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                applyIdleTimerState()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                applyIdleTimerState()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }

    private func applyIdleTimerState() {
        UIApplication.shared.isIdleTimerDisabled = isDisabled
    }
}

extension View {
    func preventsIdleTimer(_ isDisabled: Bool = true) -> some View {
        modifier(IdleTimerModifier(isDisabled: isDisabled))
    }
}

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ZZFont.body)
                .foregroundStyle(.white)
                .frame(maxWidth: 370)
                .frame(height: ZZSpacing.bottomButtonHeight)
                .background(isEnabled ? ZZColor.brand400 : ZZColor.brand100)
                .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
        }
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ZZFont.body)
                .foregroundStyle(ZZColor.gray6)
                .frame(maxWidth: .infinity)
                .frame(height: ZZSpacing.bottomButtonHeight)
                .background(ZZColor.gray3)
                .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
        }
    }
}

struct BottomButtonBar: View {
    let secondaryTitle: String?
    let primaryTitle: String
    var primaryIsEnabled: Bool = true
    var secondaryAction: (() -> Void)?
    var primaryAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let secondaryTitle {
                Button(
                    action: { secondaryAction?() },
                    label: {
                    Text(secondaryTitle)
                        .font(ZZFont.body)
                        .foregroundStyle(ZZColor.gray6)
                        .frame(maxWidth: .infinity)
                        .frame(height: ZZSpacing.bottomButtonHeight)
                        .background(ZZColor.gray2)
                        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
                    }
                )
            }

            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(ZZFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ZZSpacing.bottomButtonHeight)
                    .background(primaryIsEnabled ? ZZColor.brand400 : ZZColor.brand100)
                    .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
            }
            .disabled(!primaryIsEnabled)
        }
    }
}

struct CircularIconButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ZZColor.gray6)
                .frame(width: 48, height: 48)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        Text("\(current) / \(total)")
            .font(ZZFont.caption)
            .foregroundStyle(ZZColor.brand400)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(ZZColor.brand0)
            .clipShape(Capsule())
    }
}

struct DimmedOverlay: View {
    var opacity: Double = 0.6

    var body: some View {
        Color(red: 0.10, green: 0.15, blue: 0.18)
            .opacity(opacity)
            .ignoresSafeArea()
    }
}

struct StatusToast: View {
    let text: String
    var systemName: String?
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .bold))
            }

            Text(text)
                .font(ZZFont.body)
        }
        .foregroundStyle(isWarning ? ZZColor.brand400 : ZZColor.gray2)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(ZZColor.gray8.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius))
    }
}

struct BottomSheetHandle: View {
    var body: some View {
        Capsule()
            .fill(ZZColor.gray2)
            .frame(width: 44, height: 6)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "대화 시작") {}
        SecondaryButton(title: "취소하기") {}
        BottomButtonBar(
            secondaryTitle: "이전",
            primaryTitle: "다음",
            secondaryAction: { },
            primaryAction: { }
        )
        CircularIconButton(systemName: "house.fill") {}
        PageIndicator(current: 1, total: 3)
        StatusToast(text: "연결 성공", systemName: "checkmark.circle")
    }
    .padding()
}
