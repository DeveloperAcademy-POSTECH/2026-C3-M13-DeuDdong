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
