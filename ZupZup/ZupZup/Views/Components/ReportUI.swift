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

struct ReportBottleChartView: View {
    let items: [EmotionReportItem]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 46)
                .stroke(ZZColor.gray2, lineWidth: 22)
                .background(
                    RoundedRectangle(cornerRadius: 46)
                        .fill(.white)
                )
                .frame(width: 300, height: 500)

            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.52, green: 0.37, blue: 0.30))
                .frame(width: 94, height: 86)
                .offset(y: -292)

            Capsule()
                .fill(ZZColor.gray2.opacity(0.7))
                .frame(width: 170, height: 58)
                .offset(y: -248)

            ForEach(items) { item in
                ReportBubbleView(type: item.type, count: item.count, size: item.size)
                    .offset(item.offset)
            }
        }
        .frame(height: 610)
    }
}

struct ReportBubbleView: View {
    let type: EmotionType
    let count: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(type.swiftUIColor.opacity(0.25))
                .frame(width: size, height: size)

            Circle()
                .stroke(type.swiftUIColor, lineWidth: 2)
                .frame(width: size, height: size)

            VStack(spacing: 4) {
                Image(systemName: type.symbolName)
                    .font(.system(size: size * 0.24, weight: .bold))
                    .foregroundStyle(type.swiftUIColor)

                Text(type.compactTitle)
                    .font(.system(size: size * 0.13, weight: .bold))
                    .foregroundStyle(ZZColor.gray10)

                Text("\(count)개")
                    .font(.system(size: size * 0.14, weight: .black))
                    .foregroundStyle(type.swiftUIColor)
            }
        }
    }
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
    var certificationAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: saveAction) {
                Text("리포트 저장하기")
                    .font(ZZFont.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(ZZColor.gray9)
                    .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
            }

            SecondaryButton(title: "AR 인증샷 찍기", action: certificationAction)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ReportBottleChartView(
            items: [
                EmotionReportItem(type: .gratitude, count: 3, size: 116, offset: CGSize(width: -92, height: -20)),
                EmotionReportItem(type: .empathy, count: 2, size: 92, offset: CGSize(width: -10, height: -120)),
                EmotionReportItem(type: .affection, count: 5, size: 148, offset: CGSize(width: 82, height: -20)),
                EmotionReportItem(type: .praise, count: 7, size: 188, offset: CGSize(width: -32, height: 112))
            ]
        )

        ReportScoreRow(type: .praise, count: 7, maxCount: 10)
        ReportActionButtons(saveAction: {}, certificationAction: {})
    }
    .padding()
}
