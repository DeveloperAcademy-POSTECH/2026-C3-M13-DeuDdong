//
//  EmotionUI.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI

extension EmotionType {
    var title: String {
        switch self {
        case .affection:
            return "사랑 / 애정"
        case .encouragement:
            return "응원"
        case .praise:
            return "칭찬 / 인정"
        case .gratitude:
            return "감사"
        case .empathy:
            return "공감 / 위로"
        }
    }

    var compactTitle: String {
        switch self {
        case .affection:
            return "사랑/애정"
        case .encouragement:
            return "응원"
        case .praise:
            return "칭찬/인정"
        case .gratitude:
            return "감사"
        case .empathy:
            return "공감/위로"
        }
    }

    var description: String {
        switch self {
        case .affection:
            return "애정과 친밀감을 표현하는 말"
        case .encouragement:
            return "용기나 힘을 주는 말"
        case .praise:
            return "능력이나 결과를 인정하는 말"
        case .gratitude:
            return "고마움을 전달하는 말"
        case .empathy:
            return "마음을 알아주고 위로하는 말"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .affection: return ZZColor.emotionRed
        case .encouragement: return ZZColor.emotionYellow
        case .praise: return ZZColor.emotionGreen
        case .gratitude: return ZZColor.emotionBlue
        case .empathy: return ZZColor.emotionPurple
        }
    }

    var symbolName: String {
        switch self {
        case .affection: return "heart.fill"
        case .encouragement: return "bolt.heart.fill"
        case .praise: return "star.fill"
        case .gratitude: return "hand.thumbsup.fill"
        case .empathy: return "waveform.path.ecg"
        }
    }
}

struct EmotionRow: View {
    let type: EmotionType

    var body: some View {
        HStack(spacing: 16) {
            EmotionOrbPreview(type: type, size: 58)

            VStack(alignment: .leading, spacing: 8) {
                Text(type.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ZZColor.brand400)

                Text(": \(type.description)")
                    .font(ZZFont.caption)
                    .foregroundStyle(ZZColor.gray9)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(ZZColor.gray1)
        .clipShape(RoundedRectangle(cornerRadius: ZZSpacing.cardCornerRadius))
        .frame(maxWidth: .infinity)
        .frame(height: 81)
    }
}

struct EmotionOrbPreview: View {
    let type: EmotionType
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.95), type.swiftUIColor.opacity(0.88), type.swiftUIColor],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: size
                    )
                )

            Image(systemName: type.symbolName)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .frame(width: size, height: size)
        .shadow(color: type.swiftUIColor.opacity(0.30), radius: 8, y: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(EmotionType.allCases) { type in
            EmotionRow(type: type)
        }
    }
    .padding()
}
