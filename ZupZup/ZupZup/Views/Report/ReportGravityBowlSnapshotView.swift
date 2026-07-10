import SwiftUI

/// ReportGravityBowlView와 같은 자리에 쓰이지만, 물리 시뮬레이션 없이
/// 감정 종류/개수 데이터만으로 고정된 배치를 그린다. 이미지 저장(ImageRenderer)용.
struct ReportGravityBowlSnapshotView: View {
    let items: [EmotionReportItem]

    private let sceneSize = CGSize(width: 250, height: 300)

    var body: some View {
        ZStack {
            Image("EmptyBallGlass")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 450)

            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    orb(for: item, index: index)
                }
            }
            .frame(width: sceneSize.width, height: sceneSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 60))
            .padding(.top, 120)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image("EmptyBallGlass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text("수집된 구슬이 없어요")
                        .font(ZZFont.caption)
                        .foregroundStyle(ZZColor.gray5)
                }
                .offset(y: 64)
            }
        }
        .frame(width: 350, height: 450)
    }

    private func orb(for item: EmotionReportItem, index: Int) -> some View {
        VStack(spacing: 2) {
            Text(item.type.compactTitle)
                .font(.system(size: min(16, max(10, item.size * 0.15)), weight: .bold))
            Text("\(item.count)개")
                .font(.system(size: min(18, max(12, item.size * 0.18)), weight: .bold))
        }
        .foregroundStyle(.white)
        .frame(width: item.size, height: item.size)
        .background(
            Image(item.type.imageName)
                .resizable()
                .scaledToFill()
        )
        .clipShape(Circle())
        .position(Self.position(for: index, item: item, in: sceneSize))
    }

    /// 물리 없이 하단에 쌓인 것처럼 보이도록 고정된 자리에 배치한다.
    private static func position(for index: Int, item: EmotionReportItem, in size: CGSize) -> CGPoint {
        let slots: [CGFloat] = [0.5, 0.28, 0.72, 0.14, 0.86]
        let radius = item.size / 2
        let row = index / 3
        let slot = slots[index % slots.count]

        let positionX = min(max(size.width * slot, radius), size.width - radius)
        let bottomAnchoredY = min(size.height - radius, radius + CGFloat(row) * (item.size * 0.85) + 12)
        return CGPoint(x: positionX, y: size.height - bottomAnchoredY)
    }
}

#Preview {
    ReportGravityBowlSnapshotView(items: ReportView.reportItems(from: .preview))
        .background(ZZColor.gray1)
}
