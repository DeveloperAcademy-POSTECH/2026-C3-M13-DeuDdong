//
//  EmotionType.swift
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

internal import UIKit

    // 감정 타입은 정해진 감정에 맞게 네이밍 했는데, 원하시면 바꿔도 됩니다~!~!
enum EmotionType: String, CaseIterable, Identifiable {
    case praise // 칭찬, 인정
    case encouragement // 응원
    case affection // 사랑, 애정
    case gratitude // 감사
    case empathy // 공감, 위로

    var id: String { rawValue }

    // 색상도 피그마 hifi 기준으로 지정했습니다.
    var color: UIColor {
        switch self {
        case .praise:
            UIColor.systemGreen
        case .encouragement:
            UIColor.systemYellow
        case .affection:
            UIColor.systemRed
        case .gratitude:
            UIColor.systemBlue
        case .empathy:
            UIColor.systemPurple
        }
    }
}
