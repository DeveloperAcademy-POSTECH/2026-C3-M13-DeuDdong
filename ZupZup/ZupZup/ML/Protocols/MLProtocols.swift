//
//  MLProtocols.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import ImageIO

protocol EmotionClassifying {
    func predict(text: String) -> EmotionResult
}

@MainActor
protocol SpeechManaging: AnyObject {
    var isListening: Bool { get }
    var interimText: String { get }
    var statusText: String { get }
    var audioLevel: Double { get }
    var onFinalUtterance: ((String) -> Void)? { get set }
    var onStateChange: ((SpeechState) -> Void)? { get set }

    func requestPermissions() async -> Bool
    func start() async
    func stop()
}

protocol FaceTracking {
    func detectFaces(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> FaceTrackingResult
}

@MainActor
protocol EmotionRuntimeManaging: AnyObject {
    var speechState: SpeechState { get }
    var latestUtterance: String { get }
    var latestResult: EmotionResult? { get }
    var latestOrbEvent: EmotionOrbEvent? { get }
    var latestFaceTrackingResult: FaceTrackingResult? { get }
    var emittedOrbEventCount: Int { get }
    var debugSummary: String { get }
    var onOrbEvent: ((EmotionOrbEvent) -> Void)? { get set }

    func start() async
    func stop()
    @discardableResult
    func processUtterance(_ text: String) -> EmotionResult
    func updateFaceTracking(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> FaceTrackingResult
}
