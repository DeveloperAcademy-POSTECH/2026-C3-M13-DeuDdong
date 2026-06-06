//
//  EmotionRuntime.swift
//  ZupZup
//
//  Created by Simon on 6/2/26.
//

import CoreVideo
import Foundation
import ImageIO
import Observation

struct EmotionRuntimeConfiguration: Equatable {
    let requiresLikelySpeakerForOrb: Bool
    let minSpeakerConfidenceForOrb: Double
    let maxStoredOrbEvents: Int

    static let developer = EmotionRuntimeConfiguration(
        requiresLikelySpeakerForOrb: false,
        minSpeakerConfidenceForOrb: 0,
        maxStoredOrbEvents: 30
    )

    static let conversation = EmotionRuntimeConfiguration(
        requiresLikelySpeakerForOrb: true,
        minSpeakerConfidenceForOrb: 0.12,
        maxStoredOrbEvents: 30
    )
}

@MainActor
@Observable
final class EmotionRuntime: EmotionRuntimeManaging {
    private(set) var speechState: SpeechState = .idle
    private(set) var latestUtterance = ""
    private(set) var latestResult: EmotionResult?
    private(set) var latestOrbEvent: EmotionOrbEvent?
    private(set) var latestFaceTrackingResult: FaceTrackingResult?
    private(set) var emittedOrbEvents: [EmotionOrbEvent] = []
    private(set) var debugSummary = "ML 런타임 대기 중"

    var onOrbEvent: ((EmotionOrbEvent) -> Void)?

    private let configuration: EmotionRuntimeConfiguration
    private let speechManager: SpeechManaging
    private let classifier: EmotionClassifying?
    private let faceTracker: FaceTracking

    convenience init() {
        self.init(configuration: .developer)
    }

    convenience init(configuration: EmotionRuntimeConfiguration) {
        self.init(
            configuration: configuration,
            speechManager: SpeechManager(),
            classifier: try? EmotionClassifier(),
            faceTracker: FaceTracker()
        )
    }

    init(
        configuration: EmotionRuntimeConfiguration,
        speechManager: SpeechManaging,
        classifier: EmotionClassifying?,
        faceTracker: FaceTracking
    ) {
        self.configuration = configuration
        self.speechManager = speechManager
        self.classifier = classifier
        self.faceTracker = faceTracker

        configureSpeechCallbacks()
        if self.classifier == nil {
            debugSummary = "ML 모델을 불러오지 못했습니다"
        }
    }

    func start() async {
        debugSummary = "음성 인식 시작 중"
        await speechManager.start()
    }

    func stop() {
        speechManager.stop()
        debugSummary = "ML 런타임 정지"
    }

    @discardableResult
    func processUtterance(_ text: String) -> EmotionResult {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        latestUtterance = cleanText

        guard let classifier else {
            let result = unavailableModelResult(text: cleanText)
            latestResult = result
            latestOrbEvent = nil
            debugSummary = result.debugSummary
            return result
        }

        let result = classifier.predict(text: cleanText)
        latestResult = result
        emitOrbEventIfNeeded(from: result)
        updateDebugSummary(result: result)
        return result
    }

    func updateFaceTracking(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .right
    ) -> FaceTrackingResult {
        let result = faceTracker.detectFaces(in: pixelBuffer, orientation: orientation)
        latestFaceTrackingResult = result
        return result
    }

    private func configureSpeechCallbacks() {
        speechManager.onStateChange = { [weak self] state in
            self?.speechState = state
        }

        speechManager.onFinalUtterance = { [weak self] text in
            self?.processUtterance(text)
        }
    }

    private func emitOrbEventIfNeeded(from result: EmotionResult) {
        latestOrbEvent = nil

        guard result.shouldCreateOrb else {
            return
        }

        let speaker = eligibleSpeaker()
        if configuration.requiresLikelySpeakerForOrb, speaker == nil {
            debugSummary = "말하는 얼굴이 확인되지 않아 구슬 생성을 보류했습니다"
            return
        }

        guard let event = EmotionOrbEvent(result: result, speaker: speaker) else {
            return
        }

        latestOrbEvent = event
        emittedOrbEvents.append(event)
        trimStoredOrbEvents()
        onOrbEvent?(event)
    }

    private func eligibleSpeaker() -> FaceTrackingCandidate? {
        guard let speaker = latestFaceTrackingResult?.likelySpeaker else {
            return nil
        }

        guard speaker.speakerConfidence >= configuration.minSpeakerConfidenceForOrb else {
            return nil
        }

        return speaker
    }

    private func trimStoredOrbEvents() {
        let maxCount = max(1, configuration.maxStoredOrbEvents)
        if emittedOrbEvents.count > maxCount {
            emittedOrbEvents = Array(emittedOrbEvents.suffix(maxCount))
        }
    }

    private func updateDebugSummary(result: EmotionResult) {
        if let event = latestOrbEvent {
            debugSummary = "구슬 생성: \(event.emotion.koreanLabel) | \(result.debugSummary)"
        } else if result.shouldCreateOrb {
            debugSummary = "구슬 보류 | \(result.debugSummary)"
        } else {
            debugSummary = "구슬 없음 | \(result.debugSummary)"
        }
    }

    private func unavailableModelResult(text: String) -> EmotionResult {
        EmotionResult(
            text: text,
            polarity: .unknown,
            polarityConfidence: 0,
            polarityConfidenceAvailable: false,
            emotion: nil,
            emotionConfidence: 0,
            emotionConfidenceAvailable: false,
            candidateEmotion: nil,
            decisionReason: "runtime:model-unavailable",
            createdAt: Date()
        )
    }
}
