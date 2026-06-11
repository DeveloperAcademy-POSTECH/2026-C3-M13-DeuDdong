//
//  HapticManager.swift
//  ZupZup
//
//  Created by 노을 on 5/30/26.
//

import CoreHaptics
import OSLog
internal import UIKit

class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var engineError: HapticError?
    private var isEngineStarted = false
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

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
        prepareImpactGenerators()

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

    func playOrbGrabbed() {
        playTransient(intensity: 0.42, sharpness: 0.62)
        playImpact(intensity: 0.34)
    }

    func playOrbContact(intensity: Float) {
        let clampedIntensity = clamp(intensity, min: 0.18, max: 1.0)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.48 + clampedIntensity * 0.40)
            ],
            relativeTime: 0,
            duration: 0.11
        )
        play(events: [event])
        playImpact(intensity: clampedIntensity)
    }

    func playOrbDrop() {
        playTransient(intensity: 0.72, sharpness: 0.58)
        playImpact(intensity: 0.55)
    }

    func playOrbCollision() {
        playTransient(intensity: 0.88, sharpness: 0.72)
        playImpact(intensity: 0.78)
    }

    func playOrbCollected() {
        let events = [
            hapticTransient(intensity: 0.52, sharpness: 0.50, time: 0),
            hapticTransient(intensity: 0.38, sharpness: 0.72, time: 0.055)
        ]
        play(events: events)
        playImpact(intensity: 0.50)
    }

    func playCollectionCompleted() {
        let events = [
            hapticTransient(intensity: 0.62, sharpness: 0.70, time: 0),
            hapticTransient(intensity: 0.72, sharpness: 0.86, time: 0.08),
            hapticTransient(intensity: 0.48, sharpness: 0.94, time: 0.17)
        ]
        play(events: events)
        playImpact(intensity: 0.72)
    }

    func playParticleBurst() {
        let events = [
            hapticTransient(intensity: 0.72, sharpness: 0.82, time: 0),
            hapticTransient(intensity: 0.58, sharpness: 0.92, time: 0.045),
            hapticTransient(intensity: 0.42, sharpness: 1.0, time: 0.095)
        ]
        play(events: events)
        playImpact(intensity: 0.66)
    }

    private func playTransient(intensity: Float, sharpness: Float) {
        play(events: [hapticTransient(intensity: intensity, sharpness: sharpness, time: 0)])
    }

    private func hapticTransient(intensity: Float, sharpness: Float, time: TimeInterval) -> CHHapticEvent {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp(intensity, min: 0, max: 1)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: clamp(sharpness, min: 0, max: 1))
            ],
            relativeTime: time
        )
        return event
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }

    private func prepareImpactGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
    }

    private func playImpact(intensity: Float) {
        let normalizedIntensity = CGFloat(clamp(intensity, min: 0.1, max: 1.0))

        switch intensity {
        case ..<0.42:
            lightImpactGenerator.impactOccurred(intensity: normalizedIntensity)
        case ..<0.74:
            mediumImpactGenerator.impactOccurred(intensity: normalizedIntensity)
        default:
            heavyImpactGenerator.impactOccurred(intensity: normalizedIntensity)
        }

        prepareImpactGenerators()
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
