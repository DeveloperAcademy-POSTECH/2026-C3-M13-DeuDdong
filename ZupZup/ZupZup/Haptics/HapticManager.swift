//
//  HapticManager.swift
//  ZupZup
//
//  Created by 노을 on 5/30/26.
//

import CoreHaptics
import OSLog

class HapticManager {
    static let shared = HapticManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ZupZup", category: "Haptic")
    private var engine: CHHapticEngine?
    private var engineError: HapticError?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engineError = .notSupported
            return
        }
        do {
            engine = try CHHapticEngine()
            engine!.stoppedHandler = { [weak self] reason in
                self?.logger.info("햅틱 엔진 정지: \(reason.rawValue)")
                self?.restartEngine()
            }

            engine!.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            try engine?.start()
        } catch {
            engineError = .engineFailed
        }
    }

    private func restartEngine() {
        do {
            try engine?.start()
            engineError = nil
        } catch {
            engineError = .engineFailed
        }
    }

    /** 순간적인 탭 느낌의 햅틱을 재생합니다. */
    func playSimple() {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        play(events: [event])
    }

    private func play(events: [CHHapticEvent]) {
        if let engineError {
            logger.error("햅틱 재생 실패: \(engineError.localizedDescription)")
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine!.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            logger.error("햅틱 재생 실패: \(error.localizedDescription)")
        }
    }
}
