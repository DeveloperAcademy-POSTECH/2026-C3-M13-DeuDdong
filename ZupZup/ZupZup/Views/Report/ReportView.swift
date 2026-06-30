import SwiftUI

struct ReportView: View {
    var onHome: () -> Void
    var summary = ReportSummary()

    @State private var toastMessage: String?
    @State private var toastSystemName: String?
    @State private var toastIsWarning = false
    @State private var showSettingsAlert = false
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ReportContentView(summary: summary)

                    ReportActionButtons(
                        saveAction: { Task { await handleSave() } },
                        homeAction: onHome
                    )
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .padding(.horizontal, 28)
                }
            }
            .background(ZZColor.gray1.ignoresSafeArea())

            VStack {
                if let message = toastMessage {
                    StatusToast(
                        text: message,
                        systemName: toastSystemName,
                        isWarning: toastIsWarning
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
        }
        .alert("사진 저장 권한이 없어요", isPresented: $showSettingsAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정 > ZupZup에서 사진 추가 권한을 허용해주세요.")
        }
    }
}

// 캡처(이미지 저장) 대상이 되는 본문 영역. 버튼은 포함하지 않으며, 화면 표시와 ImageRenderer 캡처에 동일하게 재사용한다.
struct ReportContentView: View {
    var summary: ReportSummary = ReportSummary()

    private var reportItems: [EmotionReportItem] {
        ReportView.reportItems(from: summary)
    }

    private var maxEmotionCount: Int {
        max(summary.maxEmotionCount, 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Today's Report")
                    .font(ZZFont.headline)
                    .foregroundStyle(ZZColor.gray6)

                Text(ReportView.reportDateFormatter.string(from: Date()))
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
        }
        .background(ZZColor.gray1)
    }
}

#Preview {
    ReportView(onHome: {}, summary: .preview)
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

    static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter
    }()
}

extension ReportView {
    @MainActor
    private func handleSave() async {
        let result = await ReportImageSaver.saveToPhotos(summary: summary, scale: displayScale)
        switch result {
        case .success:
            showToast("사진 앱에 저장됐어요", systemName: "checkmark.circle")
        case .permissionDenied:
            showSettingsAlert = true
        case .failure:
            showToast("저장에 실패했어요", isWarning: true)
        }
    }

    private func showToast(_ message: String, systemName: String? = nil, isWarning: Bool = false) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toastMessage = message
            toastSystemName = systemName
            toastIsWarning = isWarning
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                toastMessage = nil
            }
        }
    }
}
