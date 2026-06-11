//
//  ReportUI.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI

struct EmotionReportItem: Identifiable {
    let id = UUID()
    let type: EmotionType
    let count: Int
    let size: CGFloat
    let offset: CGSize
}

struct ReportScoreRow: View {
    let type: EmotionType
    let count: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(type.swiftUIColor)
                .frame(width: 12, height: 12)

            Text(type.compactTitle)
                .font(ZZFont.body)
                .foregroundStyle(ZZColor.gray9)
                .frame(width: 76, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ZZColor.gray2)
                        .frame(height: 10)

                    Capsule()
                        .fill(type.swiftUIColor)
                        .frame(
                            width: maxCount > 0 ? geo.size.width * CGFloat(count) / CGFloat(maxCount) : 0,
                            height: 10
                        )
                }
                .frame(height: 10)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(height: 10)

            Text("\(count)개")
                .font(ZZFont.body)
                .foregroundStyle(ZZColor.gray10)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

struct ReportActionButtons: View {
    var saveAction: () -> Void
    var homeAction: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Button(action: saveAction) {
                Text("리포트 저장하기")
                    .font(ZZFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(ZZColor.gray9)
                    .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
            }
            SecondaryButton(title: "홈으로 이동하기", action: homeAction)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ReportScoreRow(type: .praise, count: 7, maxCount: 10)
        ReportActionButtons(saveAction: {}, homeAction: {})
    }
    .padding()
}
