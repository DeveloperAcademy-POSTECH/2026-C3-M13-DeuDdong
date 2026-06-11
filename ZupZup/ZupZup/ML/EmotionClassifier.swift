//
//  EmotionClassifier.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import CoreML
import Foundation

struct TextClassifierResult {
    let label: String
    let confidence: Double
    let confidenceAvailable: Bool
}

final class DynamicTextClassifier {
    private struct ClassifierConfidence {
        let value: Double
        let isAvailable: Bool

        static let unavailableProbabilityOutput = Self(value: .zero, isAvailable: false)
        static let missingPredictedLabelProbability = Self(value: .zero, isAvailable: true)

        static func available(_ value: Double) -> Self {
            Self(value: value, isAvailable: true)
        }
    }

    private let model: MLModel
    private let inputName: String
    private let outputName: String
    private let probabilitiesName: String?

    init(resourceName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: resourceName, withExtension: "mlmodelc") else {
            throw ClassifierError.modelNotFound(resourceName)
        }

        model = try MLModel(contentsOf: modelURL)

        guard let textInput = model.modelDescription.inputDescriptionsByName.first(where: { _, description in
            description.type == .string
        })?.key else {
            throw ClassifierError.stringInputNotFound(resourceName)
        }

        inputName = textInput
        outputName = model.modelDescription.predictedFeatureName
            ?? model.modelDescription.outputDescriptionsByName.first(where: { _, description in
                description.type == .string || description.type == .int64
            })?.key
            ?? "label"
        probabilitiesName = model.modelDescription.predictedProbabilitiesName
    }

    func classify(_ text: String) throws -> TextClassifierResult {
        let input = try MLDictionaryFeatureProvider(dictionary: [
            inputName: MLFeatureValue(string: text)
        ])
        let output = try model.prediction(from: input)

        guard let labelValue = output.featureValue(for: outputName) else {
            throw ClassifierError.labelOutputNotFound(outputName)
        }

        let label = labelValue.stringValue.isEmpty ? String(labelValue.int64Value) : labelValue.stringValue
        let confidence = confidence(for: label, output: output)
        return TextClassifierResult(
            label: label,
            confidence: confidence.value,
            confidenceAvailable: confidence.isAvailable
        )
    }

    private func confidence(for label: String, output: MLFeatureProvider) -> ClassifierConfidence {
        guard let probabilitiesName else {
            return .unavailableProbabilityOutput
        }

        guard let probabilities = output.featureValue(for: probabilitiesName)?.dictionaryValue else {
            return .unavailableProbabilityOutput
        }

        for (key, value) in probabilities where String(describing: key) == label {
            return .available(value.doubleValue)
        }

        return .missingPredictedLabelProbability
    }
}

final class EmotionClassifier: EmotionClassifying {
    private struct PositiveEmotionRule {
        let emotion: EmotionType
        let reason: String
        let cues: [String]
        let blockers: [String]
    }

    private let polarityGate: DynamicTextClassifier
    private let positiveType: DynamicTextClassifier
    private let polarityThreshold: Double
    private let positiveTypeThreshold: Double

    private let highPrecisionRules: [PositiveEmotionRule] = [
        PositiveEmotionRule(
            emotion: .gratitude,
            reason: "rule:gratitude",
            cues: ["감사", "고마워", "고맙", "덕분", "수고하셨", "고생하셨", "도와줘서"],
            blockers: ["감사하지", "안 감사", "고맙지 않", "고마운 줄 모르", "감사한 줄 모르"]
        ),
        PositiveEmotionRule(
            emotion: .encouragement,
            reason: "rule:encouragement",
            cues: ["힘내", "할 수 있어", "할 수 있다", "응원", "파이팅", "화이팅", "잘 될 거야", "해낼 수 있어"],
            blockers: ["응원하지", "힘내지", "할 수 없어", "못 할 거야", "안 될 거야"]
        ),
        PositiveEmotionRule(
            emotion: .empathy,
            reason: "rule:empathy",
            cues: ["힘들었겠다", "속상했겠다", "이해해", "그랬구나", "마음 아프", "위로", "괜찮아"],
            blockers: ["괜찮지 않", "이해 안", "이해하지 않", "위로가 안"]
        ),
        PositiveEmotionRule(
            emotion: .praise,
            reason: "rule:praise",
            cues: ["잘했어", "잘 하셨어", "잘한다", "멋지다", "대단해", "최고야", "훌륭", "인정", "칭찬"],
            blockers: ["칭찬 아니", "잘한 게 아니", "대단하지 않", "최고는 아니"]
        ),
        PositiveEmotionRule(
            emotion: .affection,
            reason: "rule:affection",
            cues: ["사랑해", "좋아해", "보고 싶", "소중해", "아껴", "예뻐", "귀여워"],
            blockers: ["사랑하지", "좋아하지", "보고 싶지", "소중하지"]
        )
    ]

    init(
        polarityThreshold: Double = 0.45,
        positiveTypeThreshold: Double = 0.30
    ) throws {
        polarityGate = try DynamicTextClassifier(resourceName: "PolarityGate")
        positiveType = try DynamicTextClassifier(resourceName: "PositiveEmotionType")
        self.polarityThreshold = polarityThreshold
        self.positiveTypeThreshold = positiveTypeThreshold
    }

    func predict(text: String) -> EmotionResult {
        let normalized = normalize(text)
        guard !normalized.isEmpty else {
            return emptyResult(text: text)
        }

        if let ruleResult = highPrecisionRuleOverride(for: normalized) {
            return ruleResult
        }

        do {
            let polarityResult = try polarityGate.classify(normalized)
            let polarity = PolarityLabel.fromModelLabel(polarityResult.label)

            guard polarity == .positive,
                  passesConfidenceThreshold(polarityResult, threshold: polarityThreshold) else {
                return EmotionResult(
                    text: normalized,
                    polarity: polarity,
                    polarityConfidence: polarityResult.confidence,
                    polarityConfidenceAvailable: polarityResult.confidenceAvailable,
                    emotion: nil,
                    emotionConfidence: 0,
                    emotionConfidenceAvailable: false,
                    candidateEmotion: nil,
                    decisionReason: polarityResult.confidenceAvailable
                        ? "model:polarity-gate"
                        : "model:polarity-gate:no-probability",
                    createdAt: Date()
                )
            }

            let positiveResult = try positiveType.classify(normalized)
            let candidate = EmotionType.fromModelLabel(positiveResult.label)
            let shouldEmitEmotion = passesConfidenceThreshold(positiveResult, threshold: positiveTypeThreshold)

            return EmotionResult(
                text: normalized,
                polarity: polarity,
                polarityConfidence: polarityResult.confidence,
                polarityConfidenceAvailable: polarityResult.confidenceAvailable,
                emotion: shouldEmitEmotion ? candidate : nil,
                emotionConfidence: positiveResult.confidence,
                emotionConfidenceAvailable: positiveResult.confidenceAvailable,
                candidateEmotion: candidate,
                decisionReason: positiveResult.confidenceAvailable
                    ? "model:positive-type"
                    : "model:positive-type:no-probability",
                createdAt: Date()
            )
        } catch {
            return emptyResult(text: normalized, reason: "error:\(error.localizedDescription)")
        }
    }

    private func passesConfidenceThreshold(_ result: TextClassifierResult, threshold: Double) -> Bool {
        !result.confidenceAvailable || result.confidence >= threshold
    }

    private func emptyResult(text: String, reason: String = "empty") -> EmotionResult {
        EmotionResult(
            text: text,
            polarity: .unknown,
            polarityConfidence: 0,
            polarityConfidenceAvailable: false,
            emotion: nil,
            emotionConfidence: 0,
            emotionConfidenceAvailable: false,
            candidateEmotion: nil,
            decisionReason: reason,
            createdAt: Date()
        )
    }

    private func normalize(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func highPrecisionRuleOverride(for text: String) -> EmotionResult? {
        for rule in highPrecisionRules {
            guard !rule.blockers.contains(where: { text.contains($0) }) else {
                continue
            }

            guard rule.cues.contains(where: { text.contains($0) }) else {
                continue
            }

            return EmotionResult(
                text: text,
                polarity: .positive,
                polarityConfidence: 0.98,
                polarityConfidenceAvailable: true,
                emotion: rule.emotion,
                emotionConfidence: 0.98,
                emotionConfidenceAvailable: true,
                candidateEmotion: rule.emotion,
                decisionReason: rule.reason,
                createdAt: Date()
            )
        }

        return nil
    }
}

enum ClassifierError: LocalizedError {
    case modelNotFound(String)
    case stringInputNotFound(String)
    case labelOutputNotFound(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "\(name).mlmodelc를 앱 번들에서 찾지 못했습니다."
        case .stringInputNotFound(let name):
            return "\(name) 모델에서 String 입력 feature를 찾지 못했습니다."
        case .labelOutputNotFound(let name):
            return "\(name) 출력 feature를 찾지 못했습니다."
        }
    }
}
