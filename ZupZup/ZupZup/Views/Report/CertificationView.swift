// 인증샷 화면인데 할지말지 확정 아님!!

import SwiftUI

struct CertificationView: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 카메라 화면 대용 가상 플레이스홀더
            Color.gray.opacity(0.8).ignoresSafeArea()

            // 중앙 촬영 영역 타겟 바운딩 박스 가이드 UI
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: 320, height: 420)
                .shadow(radius: 10)
                .overlay(
                    Text("인증샷 가이드 영역")
                        .font(ZZFont.smallCaption)
                        .foregroundStyle(.white.opacity(0.6))
                )

            VStack {
                // 상단 네비게이션 헤더 바
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .padding(.top, 16)

                Spacer()

                // 하단 셔터 버튼 영역 대치
                VStack(spacing: 20) {
                    Text("이쁜 순간을 기록해 보세요!")
                        .font(ZZFont.caption)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)

                    Button(action: onDismiss) {
                        Circle()
                            .fill(.white)
                            .frame(width: 76, height: 76)
                            .overlay(
                                Circle()
                                    .stroke(ZZColor.brand400, lineWidth: 4)
                                    .padding(4)
                            )
                            .shadow(radius: 6)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    CertificationView(onDismiss: {})
}
