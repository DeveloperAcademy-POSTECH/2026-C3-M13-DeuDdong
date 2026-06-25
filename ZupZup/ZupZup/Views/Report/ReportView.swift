import SwiftUI

struct ReportView: View {
    var onSave: () -> Void
    var onHome: () -> Void
    var collectedCount: Int = 0
    let reportMockData = [
        EmotionReportItem(type: .gratitude, count: 3, size: 116, offset: CGSize(width: -80, height: -20)),
        EmotionReportItem(type: .empathy, count: 2, size: 92, offset: CGSize(width: -10, height: -120)),
        EmotionReportItem(type: .affection, count: 5, size: 148, offset: CGSize(width: 82, height: -20)),
        EmotionReportItem(type: .praise, count: 7, size: 188, offset: CGSize(width: -32, height: 112)),
        EmotionReportItem(type: .encouragement, count: 1, size: 80, offset: CGSize(width: 80, height: 100))
    ]
    var body: some View {
        ZStack {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ReportContentView(collectedCount: collectedCount)

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
    ReportView(onSave: {}, onHome: {})
}
