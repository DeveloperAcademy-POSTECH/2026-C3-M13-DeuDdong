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

    private var engine: CHHapticEngine?
    private var engineError: HapticError?
    private var isEngineStarted = false

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engineError = .notSupported
            return
        }
        do {
            let engine = try CHHapticEngine()
            self.engine = engine

            engine.stoppedHandler = { [weak self] reason in
                self?.isEngineStarted = false
                Logger.haptic.info("햅틱 엔진 정지: \(reason.rawValue, privacy: .public)")
                self?.restartEngine()
            }

            engine.resetHandler = { [weak self] in
                self?.isEngineStarted = false
                self?.restartEngine()
            }

            try engine.start()
            isEngineStarted = true
        } catch {
            engineError = .engineFailed
            Logger.haptic.error("햅틱 엔진 생성/시작 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func restartEngine() {
        do {
            try engine?.start()
            isEngineStarted = true
            engineError = nil
        } catch {
            isEngineStarted = false
            engineError = .engineFailed
        }
    }

    func prepare() {
        do {
            try ensureEngineRunning()
        } catch {
            Logger.haptic.error("햅틱 엔진 준비 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    /** 순간적인 탭 느낌의 햅틱을 재생합니다. */
    func playSimple() {
        playTransient(intensity: 1.0, sharpness: 0.8)
    }

    func playCountdownTick(count: Int) {
        let isFinalTick = count == 1
        playTransient(
            intensity: isFinalTick ? 0.82 : 0.48,
            sharpness: isFinalTick ? 0.82 : 0.64
        )
    }

    func playOrbContact(intensity: Float) {
        let clampedIntensity = clamp(intensity, min: 0.08, max: 0.9)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.42 + clampedIntensity * 0.35)
            ],
            relativeTime: 0,
            duration: 0.08
        )
        play(events: [event])
    }

    func playOrbCollision() {
        playTransient(intensity: 0.68, sharpness: 0.52)
    }

    private func playTransient(intensity: Float, sharpness: Float) {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp(intensity, min: 0, max: 1)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: clamp(sharpness, min: 0, max: 1))
            ],
            relativeTime: 0
        )
        play(events: [event])
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }

    private func ensureEngineRunning() throws {
        guard let engine else {
            throw engineError ?? HapticError.engineFailed
        }

        guard !isEngineStarted else { return }

        try engine.start()
        isEngineStarted = true
        engineError = nil
    }

    private func play(events: [CHHapticEvent]) {
        guard let engine else {
            Logger.haptic.error("햅틱 재생 실패: \((self.engineError ?? .engineFailed).localizedDescription)")
            return
        }

        do {
            try ensureEngineRunning()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            isEngineStarted = false
            Logger.haptic.error("햅틱 재생 실패: \(error.localizedDescription)")
        }
    }
}
