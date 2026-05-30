//
//  HapticManager.swift
//  ZupZup
//
//  Created by 노을 on 5/30/26.
//

import CoreHaptics

class HapticManager {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?
    private var engineError: HapticError?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engineError = .notSupported
            return
        }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engineError = .engineFailed
        }
    }

    func playSimple() throws {
        if let engineError { throw engineError }
        guard let engine else { throw HapticError.engineFailed }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            throw HapticError.playFailed
        }
    }
}
