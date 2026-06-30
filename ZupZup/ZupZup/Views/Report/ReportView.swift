import SwiftUI

struct ReportView: View {
    var onSave: () -> Void
    var onHome: () -> Void
    var summary = ReportSummary()

    private var reportItems: [EmotionReportItem] {
        Self.reportItems(from: summary)
    }

    private var maxEmotionCount: Int {
        max(summary.maxEmotionCount, 1)
    }

    var body: some View {
        ZStack {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // 상단 타이틀부 라벨
                    VStack(spacing: 6) {
                        Text("Today's Report")
                            .font(ZZFont.headline)
                            .foregroundStyle(ZZColor.gray6)

                        Text(Self.reportDateFormatter.string(from: Date()))
                            .font(ZZFont.body)
                            .foregroundStyle(ZZColor.gray5)
                    }
                    .padding(.top, 25)

                    ReportGravityBowlView(items: reportItems)
                        .padding(.top, 30)
                        .padding(.bottom, 18)

                    HStack {
                        Text("총 수집 개수")
                            .font(ZZFont.body)
                            .foregroundStyle(ZZColor.gray6)

                        Spacer()

                        Text("\(summary.totalCollectedCount)개")
                            .font(ZZFont.headline)
                            .foregroundStyle(ZZColor.brand400)
                    }
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: ZZSpacing.cardCornerRadius
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                    .padding(.horizontal, ZZSpacing.screenHorizontal)

                    VStack(spacing: 10) {
                        ForEach(EmotionType.allCases) { emotion in
                            ReportScoreRow(
                                type: emotion,
                                count: summary.count(for: emotion),
                                maxCount: maxEmotionCount
                            )
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: ZZSpacing.cardCornerRadius
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
                    .padding(.top, 14)

                    ReportActionButtons(
                        saveAction: onSave,
                        homeAction: onHome
                    )
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .padding(.horizontal, 28)
                }
            }
            .background(ZZColor.gray1.ignoresSafeArea())
        }
    }
}

// 캡처(이미지 저장) 대상이 되는 본문 영역. 버튼은 포함하지 않으며, 화면 표시와 ImageRenderer 캡처에 동일하게 재사용한다.
struct ReportContentView: View {
    var collectedCount: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Today's Report")
                    .font(ZZFont.headline)
                    .foregroundStyle(ZZColor.gray6)

                Text("2026년 06월 11일")
                    .font(ZZFont.body)
                    .foregroundStyle(ZZColor.gray5)
            }
            .padding(.top, 25)

            Image("ReportGlassImage")
                .resizable()
                .scaledToFit()
                .frame(width: 350)
                .padding(.top, 30)
                .padding(.bottom, 30)

            HStack {
                Text("총 수집 개수")
                    .font(ZZFont.body)
                    .foregroundStyle(ZZColor.gray6)

                Spacer()

                Text("\(collectedCount)개")
                    .font(ZZFont.headline)
                    .foregroundStyle(ZZColor.brand400)
            }
            .padding(.horizontal, ZZSpacing.screenHorizontal)
            .padding(.vertical, 24)
            .background(Color.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ZZSpacing.cardCornerRadius
                )
            )
            .shadow(
                color: Color.black.opacity(0.04),
                radius: 12,
                x: 0,
                y: 4
            )
            .padding(.horizontal, ZZSpacing.screenHorizontal)
        }
        .background(ZZColor.gray1)
    }
}

#Preview {
    ReportView(onSave: {}, onHome: {}, summary: .preview)
}

extension ReportView {
    static func reportItems(from summary: ReportSummary) -> [EmotionReportItem] {
        EmotionType.allCases.compactMap { emotion in
            let count = summary.count(for: emotion)
            guard count > 0 else { return nil }

            return EmotionReportItem(
                type: emotion,
                count: count,
                size: orbSize(count: count, maxCount: max(summary.maxEmotionCount, 1))
            )
        }
    }

    private static func orbSize(count: Int, maxCount: Int) -> CGFloat {
        let minSize: CGFloat = 64
        let maxSize: CGFloat = 116
        guard maxCount > 1 else { return maxSize }

        let ratio = sqrt(CGFloat(count) / CGFloat(maxCount))
        return minSize + (maxSize - minSize) * ratio
    }

    private static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter
    }()
}
