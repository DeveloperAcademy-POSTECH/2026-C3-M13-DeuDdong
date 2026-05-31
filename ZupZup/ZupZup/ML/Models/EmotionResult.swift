//
//  EmotionResult.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import Foundation

enum PolarityLabel: String, Equatable {
    case positive = "긍정"
    case negative = "부정"
    case neutral = "중립"
    case unknown
}

struct EmotionResult: Equatable {
    let text: String
    let polarity: PolarityLabel
    let polarityConfidence: Double
    let emotion: EmotionType?
    let emotionConfidence: Double
    let candidateEmotion: EmotionType?
    let createdAt: Date

    var shouldCreateOrb: Bool {
        polarity == .positive && emotion != nil
    }

    var displayEmotion: EmotionType? {
        emotion ?? candidateEmotion
    }
}

extension EmotionType {
    var koreanLabel: String {
        switch self {
        case .praise:
            return "칭찬/인정"
        case .encouragement:
            return "응원"
        case .affection:
            return "사랑/애정"
        case .gratitude:
            return "감사"
        case .empathy:
            return "공감/위로"
        }
    }

    static func fromModelLabel(_ label: String) -> EmotionType? {
        switch label {
        case "칭찬/인정", "praise":
            return .praise
        case "응원", "encouragement", "cheer":
            return .encouragement
        case "사랑/애정", "affection", "love":
            return .affection
        case "감사", "gratitude":
            return .gratitude
        case "공감/위로", "empathy", "comfort":
            return .empathy
        default:
            return nil
        }
    }
}
