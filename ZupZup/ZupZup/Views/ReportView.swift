import SwiftUI

struct ReportView: View {
    var onSave: () -> Void
    var onCertify: () -> Void

    // 10.0.pdf 시안상의 수치와 원형 버블 좌표 규격을 픽스한 모킹 컬렉션 데이터
    let reportMockData = [
        EmotionReportItem(type: .gratitude, count: 3, size: 116, offset: CGSize(width: -80, height: -20)),
        EmotionReportItem(type: .empathy, count: 2, size: 92, offset: CGSize(width: -10, height: -120)),
        EmotionReportItem(type: .affection, count: 5, size: 148, offset: CGSize(width: 82, height: -20)),
        EmotionReportItem(type: .praise, count: 7, size: 188, offset: CGSize(width: -32, height: 112)),
        EmotionReportItem(type: .encouragement, count: 1, size: 80, offset: CGSize(width: 80, height: 100))
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // 상단 타이틀부 라벨
                VStack(spacing: 6) {
                    Text("Today's Report")
                        .font(ZZFont.headline)
                        .foregroundStyle(ZZColor.gray6)

                    Text("2026년 06월 11일")
                        .font(ZZFont.body)
                        .foregroundStyle(ZZColor.gray5)
                }
                .padding(.top, 30)

                // 기존 제작해주신 소중한 유리병 그래픽 컴포넌트 호출 매핑
                ReportBottleChartView(items: reportMockData)
                    .padding(.top, 70)

                    HStack {
                        Text("총 수집 개수")
                            .font(ZZFont.body)
                            .foregroundStyle(ZZColor.gray6)
                        Spacer()
                        Text("18개")
                            .font(ZZFont.headline)
                            .foregroundStyle(ZZColor.brand400)
                    }

                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .padding(.vertical, 24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .padding(.horizontal, ZZSpacing.screenHorizontal)

                // 액션 제어 하단 더블 버튼 바 호출
                ReportActionButtons(
                    saveAction: onSave,
                    certificationAction: onCertify
                )
                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .background(ZZColor.gray1.ignoresSafeArea())
    }
}

// 중복 명칭 혼선 방지를 위해 CommonUI 내부 컴포넌트로 브릿지 연결하는 구조체
struct ReportRowItemBridge: View {
    let type: EmotionType
    let count: Int
    let maxCount: Int = 7 // 비율 계산용 가상 최댓값

    var body: some View {
        HStack(spacing: 12) {
            // 직접 구현해두신 예쁜 원형 감정 구슬 미니 컴포넌트 호출
            EmotionOrbPreview(type: type, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(ZZFont.body)
                    .foregroundStyle(ZZColor.gray10)
            }

            Spacer()

            Text("\(count)개")
                .font(ZZFont.body)
                .fontWeight(.bold)
                .foregroundStyle(ZZColor.gray8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReportView(onSave: {}, onCertify: {})
}
