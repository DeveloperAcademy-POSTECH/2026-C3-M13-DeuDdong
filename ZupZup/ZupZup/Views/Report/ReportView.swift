import SwiftUI

struct ReportView: View {
    var onHome: () -> Void
    var summary = ReportSummary()

    @State private var showSettingsAlert = false
    @State private var saveResultToast: SaveResultToast?

    var body: some View {
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
        .overlay(alignment: .top) {
            if let saveResultToast {
                StatusToast(
                    text: saveResultToast.text,
                    systemName: saveResultToast.systemName,
                    isWarning: saveResultToast.isWarning
                )
                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
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

struct SaveResultToast: Equatable {
    let text: String
    let systemName: String
    let isWarning: Bool

    static let success = SaveResultToast(text: "사진 앱에 저장됐어요", systemName: "checkmark.circle", isWarning: false)
    static let failure = SaveResultToast(text: "저장에 실패했어요. 다시 시도해주세요", systemName: "exclamationmark.circle", isWarning: true)
}

// 리포트 화면의 본문 영역. 버튼은 포함하지 않는다.
struct ReportContentView: View {
    var summary: ReportSummary = ReportSummary()
    /// 이미지 저장용으로 렌더링할 때는 물리 시뮬레이션 없는 고정 배치 구슬 그릇을 사용한다.
    var usesStaticBowl: Bool = false

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

            Group {
                if usesStaticBowl {
                    ReportGravityBowlSnapshotView(items: reportItems)
                } else {
                    ReportGravityBowlView(items: reportItems)
                }
            }
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
        let result = await ReportImageSaver.requestPermission()
        switch result {
        case .granted:
            await captureAndSave()
        case .denied:
            showSettingsAlert = true
        }
    }

    @MainActor
    private func captureAndSave() async {
        guard let image = ReportImageSaver.renderImage(from: summary) else {
            showSaveResultToast(.failure)
            return
        }

        let success = await ReportImageSaver.save(image)
        showSaveResultToast(success ? .success : .failure)
    }

    @MainActor
    private func showSaveResultToast(_ toast: SaveResultToast) {
        withAnimation(.easeOut(duration: 0.2)) {
            saveResultToast = toast
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) {
                saveResultToast = nil
            }
        }
    }
}
