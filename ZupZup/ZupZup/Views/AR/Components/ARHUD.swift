//
//  ARHUD.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI

struct ARHomeButtonDark: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "house.fill")
                .font(.system(size: 20, weight: .semibold)) // 기존 CircularIconButton 크기에 맞춤
                .foregroundStyle(ZZColor.gray0)              // 아이콘 색상 고정
                .frame(width: 44, height: 44)               // 일반적인 상단 히트박스 원형 크기
                .background(ZZColor.gray7.opacity(0.5))     // 배경 원 색상 + 투명도 50%
                .clipShape(Circle())
        }
    }
}

struct ARHomeButtonLight: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "house.fill")
                .font(.system(size: 20, weight: .semibold)) // 기존 CircularIconButton 크기에 맞춤
                .foregroundStyle(ZZColor.gray0)              // 아이콘 색상 고정
                .frame(width: 44, height: 44)               // 일반적인 상단 히트박스 원형 크기
                .background(ZZColor.gray3.opacity(0.5))     // 배경 원 색상 + 투명도 50%
                .clipShape(Circle())
        }
    }
}

struct ARBackButtonDark: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ZZColor.gray0)
                .frame(width: 44, height: 44)
                .background(ZZColor.gray7.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

struct ARBackButtonLight: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ZZColor.gray0)
                .frame(width: 44, height: 44)
                .background(ZZColor.gray3.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

struct ARHelpButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "questionmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(ZZColor.gray0)
                .frame(width: 44, height: 44)
                .background(ZZColor.gray7.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

struct ARInstructionText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(ZZFont.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .shadow(radius: 4)
    }
}

// ==========================================
// 2. 글래스모피즘 스타일의 OrbCountCapsule
// ==========================================
struct OrbCountCapsule: View {
    let current: Int
    let total: Int
    var isComplete: Bool = false

    // 두 번째 사진의 외곽선 흐림 그라데이션 컬러 스펙 정의
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.6), .white.opacity(0.1), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Text("\(current) / \(total)")
            .font(.system(size: 24, weight: .bold))
            // 완료 상태가 아닐 때도 완전한 흰색보다는 부드러운 화이트 톤 유지
            .foregroundStyle(isComplete ? ZZColor.brand400 : .white)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    if isComplete {
                        ZZColor.brand0
                    } else {
                        // 기본 상태: gray3의 투명도 50% 투영 배경 적용
                        ZZColor.gray3.opacity(0.5)
                    }
                }
            )
            .clipShape(Capsule())
            // 외곽선에 그라데이션을 입혀 유리 질감(Glassmorphism) 극대화
            .overlay(
                Capsule()
                    .strokeBorder(glassGradient, lineWidth: 1.5)
            )
    }
}

struct ConversationTimerView: View {
    let remainingSeconds: Int

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(timeString)
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(.white)
                .shadow(radius: 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// ==========================================
// 3. 페이스 가이드라인 링 우측 그라데이션 보정
// ==========================================
struct FaceGuideRing: View {

    var progress: Double = 0.0
    var size: CGFloat = 240

    private var ringGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: 0xFFE3D6),
                Color(hex: 0xFF590A)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {

        ZStack {

            Circle()
                .stroke(
                    ZZColor.gray4.opacity(0.4),
                    lineWidth: 4
                )

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct AutoCollectButton: View {
    let isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text("자동 수집하기")
                    .font(ZZFont.smallCaption)

            }
            .foregroundStyle(ZZColor.gray0)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isEnabled ? ZZColor.gray7 : ZZColor.gray5)
            .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.buttonCornerRadius))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

// ==========================================
// 2. 시안 매칭형 하단 그라데이션 카운트다운 (CountdownOverlay)
// ==========================================
struct CountdownOverlay: View {
    let count: Int

    var body: some View {
        VStack {
            Spacer()

            // 시안 스펙: 높이 330, 하단 gray9(100%) -> 상단 gray0(0%) 그라데이션 레이어
            ZStack(alignment: .bottom) { // 정렬 기준을 하단 중앙(.bottom)으로 변경
                LinearGradient(
                    colors: [
                        ZZColor.gray9,                  // 맨 아래: gray9 100%
                        ZZColor.gray9.opacity(0.8),
                        ZZColor.gray9.opacity(0.3),
                        ZZColor.gray0.opacity(0.0)      // 맨 위: gray0 0% (완전 투명)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 330) // 배경 그라데이션 높이 330 고정

                // 가이드 문구 및 카운트 링 레이아웃 (가운데 정렬화)
                HStack(spacing: 20) {
                    Spacer() // 왼쪽 여백을 밀어주어 가운데로 정렬

                    // ZZColor.brand400 단색 원형 카운트 링
                    ZStack {
                        Circle()
                            .stroke(ZZColor.brand400, lineWidth: 3)
                            .frame(width: 58, height: 58)

                        Text("\(count)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(ZZColor.brand400)
                    }

                    // 우측 동의 안내 문구 텍스트 콤보 (중앙 정렬 보정)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("잠시후 대화가 시작됩니다")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text("상대의 동의하에 진행해주세요")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer() // 오른쪽 여백을 밀어주어 가운데로 정렬
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50) // 하단 홈 인디케이터 방어 여백 내 안착
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TimeoutNoticeOverlay: View {
    let title: String
    let subtitle: String?
    var cancelAction: (() -> Void)? = nil

    var body: some View {
        ZStack {
            DimmedOverlay()

            VStack(spacing: 18) {
                Spacer()

                VStack(spacing: 14) {
                    Text(title)
                        .font(ZZFont.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    if let subtitle {
                        Text(subtitle)
                            .font(ZZFont.body)
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                if let cancelAction {
                    SecondaryButton(title: "취소하기", action: cancelAction)
                        .padding(.horizontal, ZZSpacing.screenHorizontal)
                }
            }
            .padding(.bottom, 34)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack(spacing: 28) {
            HStack {
                ARHomeButtonDark {}
                ARBackButtonDark {}
                ARHelpButton {}
            }

            OrbCountCapsule(current: 0, total: 11) // 두 번째 시안 테스트 매칭 (0/11)
            ConversationTimerView(remainingSeconds: 10)
            CountdownOverlay(count: 3)
            FaceGuideRing(progress: 1.0)          // 첫 번째 시안 테스트용 가이드 풀 링
            AutoCollectButton(isEnabled: true) {}
        }
    }
}
