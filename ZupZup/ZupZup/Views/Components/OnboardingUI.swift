//
//  OnboardingUI.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI

struct OnboardingStepHeader: View {
    let title: String
    var subtitle: String = "모든 표현이 정확히 분리되지 않을 수 있습니다"

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(ZZFont.title)
                .foregroundStyle(ZZColor.gray10)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text(subtitle)
                .font(ZZFont.caption)
                .foregroundStyle(ZZColor.gray5)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct OnboardingCardView<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 18) {
            content
                .frame(maxWidth: 279)
                .frame(height: 279)
                .background(ZZColor.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(spacing: 8) {
                Text(title)
                    .font(ZZFont.subheadline)
                    .foregroundStyle(ZZColor.gray10)

                Text(description)
                    .font(ZZFont.body)
                    .foregroundStyle(ZZColor.gray6)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: 311)
        .frame(height: 404)
        .background(ZZColor.gray2)
        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius))
    }
}

struct PermissionCardData: Identifiable {
    let id = UUID()
    let systemName: String
    let title: String
    let description: String
}

struct PermissionSectionView: View {
    let title: String
    let cards: [PermissionCardData]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(ZZFont.subheadline)
                .foregroundStyle(ZZColor.gray10)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(cards) { card in
                    PermissionRow(data: card)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PermissionRow: View {
    let data: PermissionCardData

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: data.systemName)
                .font(.system(size: 28))
                .foregroundStyle(ZZColor.gray5)
                .frame(width: 70, height: 70)
                .overlay(Circle().stroke(ZZColor.gray5, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text(data.title)
                    .font(ZZFont.body)
                    .foregroundStyle(ZZColor.gray10)

                Text(": \(data.description)")
                    .font(ZZFont.smallCaption)
                    .foregroundStyle(ZZColor.gray6)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .overlay(
            RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius)
                .stroke(ZZColor.gray3, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius))
    }
}

#Preview {
    VStack(spacing: 24) {
        OnboardingStepHeader(title: "대화 속 긍정의 말을 모아\n나의 구슬들을 모아보세요")

        OnboardingCardView(title: "상대와 대화", description: "카메라로 상대를 비추며\n대화를 진행합니다") {
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 110))
                .foregroundStyle(ZZColor.gray9)
        }

        PermissionSectionView(
            title: "필수적 접근 권한",
            cards: [
                PermissionCardData(systemName: "camera.fill", title: "카메라", description: "AR 환경 구성용")
            ]
        )
    }
    .padding()
}
