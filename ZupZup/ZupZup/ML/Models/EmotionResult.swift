//
//  EmotionResult.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import CoreGraphics
import Foundation

enum PolarityLabel: String, Equatable {
    case positive = "긍정"
    case negative = "부정"
    case neutral = "중립"
    case unknown

    static func fromModelLabel(_ label: String) -> PolarityLabel {
        switch label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "긍정", "positive", "pos", "1":
            return .positive
        case "부정", "negative", "neg", "2":
            return .negative
        case "중립", "neutral", "neu", "3":
            return .neutral
        default:
            return .unknown
        }
    }
}

struct EmotionResult: Equatable {
    let text: String
    let polarity: PolarityLabel
    let polarityConfidence: Double
    let polarityConfidenceAvailable: Bool
    let emotion: EmotionType?
    let emotionConfidence: Double
    let emotionConfidenceAvailable: Bool
    let candidateEmotion: EmotionType?
    let decisionReason: String
    let createdAt: Date

    init(
        text: String,
        polarity: PolarityLabel,
        polarityConfidence: Double,
        polarityConfidenceAvailable: Bool = true,
        emotion: EmotionType?,
        emotionConfidence: Double,
        emotionConfidenceAvailable: Bool = true,
        candidateEmotion: EmotionType?,
        decisionReason: String = "",
        createdAt: Date
    ) {
        self.text = text
        self.polarity = polarity
        self.polarityConfidence = polarityConfidence
        self.polarityConfidenceAvailable = polarityConfidenceAvailable
        self.emotion = emotion
        self.emotionConfidence = emotionConfidence
        self.emotionConfidenceAvailable = emotionConfidenceAvailable
        self.candidateEmotion = candidateEmotion
        self.decisionReason = decisionReason
        self.createdAt = createdAt
    }

    var shouldCreateOrb: Bool {
        polarity == .positive && emotion != nil
    }

    var displayEmotion: EmotionType? {
        emotion ?? candidateEmotion
    }

    var confidenceSummary: String {
        let polarityMark = polarityConfidenceAvailable ? percentage(polarityConfidence) : "N/A"
        let emotionMark = emotionConfidenceAvailable ? percentage(emotionConfidence) : "N/A"
        let emotionLabel = displayEmotion?.koreanLabel ?? "없음"
        return "polarity=\(polarity.rawValue)(\(polarityMark)), emotion=\(emotionLabel)(\(emotionMark))"
    }

    var debugSummary: String {
        let reason = decisionReason.isEmpty ? "model" : decisionReason
        return "\(reason) | \(confidenceSummary) | \(text)"
    }

    private func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

struct EmotionOrbEvent: Identifiable, Equatable {
    let id: UUID
    let emotion: EmotionType
    let sourceText: String
    let polarityConfidence: Double
    let emotionConfidence: Double
    let speakerID: UUID?
    let speakerMouthCenter: CGPoint?
    let createdAt: Date

    init?(
        result: EmotionResult,
        speaker: FaceTrackingCandidate? = nil,
        id: UUID = UUID()
    ) {
        guard let emotion = result.emotion else { return nil }

        self.id = id
        self.emotion = emotion
        self.sourceText = result.text
        self.polarityConfidence = result.polarityConfidence
        self.emotionConfidence = result.emotionConfidence
        self.speakerID = speaker?.id
        self.speakerMouthCenter = speaker?.mouthCenter
        self.createdAt = result.createdAt
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
