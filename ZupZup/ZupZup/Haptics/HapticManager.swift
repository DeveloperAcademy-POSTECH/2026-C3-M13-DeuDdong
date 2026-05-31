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

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Haptic")
    private var engine: CHHapticEngine?
    private var engineError: HapticError?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engineError = .notSupported
            return
        }
        do {
            engine = try CHHapticEngine()
            engine!.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                    self?.engineError = nil
                } catch {
                    self?.engineError = .engineFailed
                }
            }
            try engine?.start()
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

    /**
     이벤트 배열을 받아 햅틱 패턴을 생성하고 재생합니다.
     엔진 초기화에 실패했거나 재생 중 오류가 발생하면 콘솔에 로그를 남기고  종료합니다.
     - Parameter events: 재생할 CHHapticEvent 배열
     */
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
