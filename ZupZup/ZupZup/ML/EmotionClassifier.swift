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
}

final class DynamicTextClassifier {
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
        return TextClassifierResult(label: label, confidence: confidence(for: label, output: output))
    }

    private func confidence(for label: String, output: MLFeatureProvider) -> Double {
        guard
            let probabilitiesName,
            let probabilities = output.featureValue(for: probabilitiesName)?.dictionaryValue
        else {
            return 1
        }

        for (key, value) in probabilities where String(describing: key) == label {
            return value.doubleValue
        }

        return 0
    }
}

final class EmotionClassifier: EmotionClassifying {
    private let polarityGate: DynamicTextClassifier
    private let positiveType: DynamicTextClassifier
    private let polarityThreshold: Double
    private let positiveTypeThreshold: Double

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
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return emptyResult(text: text)
        }

        if let gratitudeResult = gratitudeOverride(for: normalized) {
            return gratitudeResult
        }

        do {
            let polarityResult = try polarityGate.classify(normalized)
            let polarity = PolarityLabel(rawValue: polarityResult.label) ?? .unknown

            guard polarity == .positive, polarityResult.confidence >= polarityThreshold else {
                return EmotionResult(
                    text: normalized,
                    polarity: polarity,
                    polarityConfidence: polarityResult.confidence,
                    emotion: nil,
                    emotionConfidence: 0,
                    candidateEmotion: nil,
                    createdAt: Date()
                )
            }

            let positiveResult = try positiveType.classify(normalized)
            let candidate = EmotionType.fromModelLabel(positiveResult.label)

            return EmotionResult(
                text: normalized,
                polarity: polarity,
                polarityConfidence: polarityResult.confidence,
                emotion: positiveResult.confidence >= positiveTypeThreshold ? candidate : nil,
                emotionConfidence: positiveResult.confidence,
                candidateEmotion: candidate,
                createdAt: Date()
            )
        } catch {
            return emptyResult(text: normalized)
        }
    }

    private func emptyResult(text: String) -> EmotionResult {
        EmotionResult(
            text: text,
            polarity: .unknown,
            polarityConfidence: 0,
            emotion: nil,
            emotionConfidence: 0,
            candidateEmotion: nil,
            createdAt: Date()
        )
    }

    private func gratitudeOverride(for text: String) -> EmotionResult? {
        let blockers = ["감사하지", "안 감사", "고맙지 않", "고마운 줄 모르"]
        guard !blockers.contains(where: { text.contains($0) }) else {
            return nil
        }

        let gratitudeCues = ["감사", "고마워", "고맙", "덕분", "수고하셨", "고생하셨"]
        guard gratitudeCues.contains(where: { text.contains($0) }) else {
            return nil
        }

        return EmotionResult(
            text: text,
            polarity: .positive,
            polarityConfidence: 0.96,
            emotion: .gratitude,
            emotionConfidence: 0.96,
            candidateEmotion: .gratitude,
            createdAt: Date()
        )
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
