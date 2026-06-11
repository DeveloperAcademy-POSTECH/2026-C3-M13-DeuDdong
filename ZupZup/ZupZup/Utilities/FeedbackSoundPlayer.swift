//
//  FeedbackSoundPlayer.swift
//  ZupZup
//

import AVFoundation
import Foundation
import OSLog

@MainActor
enum FeedbackSoundPlayer {
    private enum Effect: Hashable {
        case orbGrabbed
        case orbCollected

        var frequencies: [Double] {
            switch self {
            case .orbGrabbed:
                [1_140, 1_860, 2_740]
            case .orbCollected:
                [920, 1_520, 2_360, 3_480]
            }
        }

        var duration: Double {
            switch self {
            case .orbGrabbed:
                0.16
            case .orbCollected:
                0.18
            }
        }

        var amplitude: Double {
            switch self {
            case .orbGrabbed:
                0.36
            case .orbCollected:
                0.46
            }
        }

        var noiseAmount: Double {
            switch self {
            case .orbGrabbed:
                0.06
            case .orbCollected:
                0.10
            }
        }

        var decay: Double {
            switch self {
            case .orbGrabbed:
                18
            case .orbCollected:
                16
            }
        }

        var resourceName: String {
            switch self {
            case .orbGrabbed:
                "glass_orb_drop"
            case .orbCollected:
                "glass_orb_collision"
            }
        }

        var resourceVolume: Float {
            switch self {
            case .orbGrabbed:
                0.85
            case .orbCollected:
                0.95
            }
        }
    }

    private static var players: [Effect: AVAudioPlayer] = [:]
    private static var isAudioSessionPrepared = false

    static func prepare() {
        prepareAudioSessionIfNeeded()
        for effect in [Effect.orbGrabbed, .orbCollected] {
            _ = player(for: effect)
        }
    }

    static func playOrbGrabbed() {
        play(.orbGrabbed)
    }

    static func playOrbCollected() {
        play(.orbCollected)
    }

    private static func play(_ effect: Effect) {
        prepareAudioSessionIfNeeded()
        guard let player = player(for: effect) else { return }

        player.currentTime = 0
        player.play()
    }

    private static func player(for effect: Effect) -> AVAudioPlayer? {
        if let player = players[effect] {
            return player
        }

        do {
            let player = try bundledPlayer(for: effect) ?? synthesizedPlayer(for: effect)
            player.volume = effect.resourceVolume
            player.prepareToPlay()
            players[effect] = player
            return player
        } catch {
            Logger.haptic.error("피드백 사운드 준비 실패: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func bundledPlayer(for effect: Effect) throws -> AVAudioPlayer? {
        guard let url = bundledSoundURL(for: effect.resourceName) else {
            return nil
        }

        return try AVAudioPlayer(contentsOf: url)
    }

    private static func synthesizedPlayer(for effect: Effect) throws -> AVAudioPlayer {
        try AVAudioPlayer(data: wavData(for: effect))
    }

    private static func bundledSoundURL(for resourceName: String) -> URL? {
        let bundle = Bundle.main
        let candidateSubdirectories: [String?] = [
            nil,
            "Sounds/KenneyImpactSounds",
            "Resources/Sounds/KenneyImpactSounds"
        ]

        for subdirectory in candidateSubdirectories {
            if let url = bundle.url(
                forResource: resourceName,
                withExtension: "wav",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }

    private static func prepareAudioSessionIfNeeded() {
        guard !isAudioSessionPrepared else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.mixWithOthers, .defaultToSpeaker]
            )
            try session.setActive(true)
            isAudioSessionPrepared = true
        } catch {
            Logger.haptic.error("피드백 사운드 세션 준비 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func wavData(for effect: Effect) -> Data {
        let sampleRate = 44_100
        let channelCount = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let sampleCount = Int(effect.duration * Double(sampleRate))
        let dataByteCount = sampleCount * bytesPerSample * channelCount
        var data = Data()

        data.append("RIFF".data(using: .ascii) ?? Data())
        append(UInt32(36 + dataByteCount), to: &data)
        data.append("WAVE".data(using: .ascii) ?? Data())
        data.append("fmt ".data(using: .ascii) ?? Data())
        append(UInt32(16), to: &data)
        append(UInt16(1), to: &data)
        append(UInt16(channelCount), to: &data)
        append(UInt32(sampleRate), to: &data)
        append(UInt32(sampleRate * channelCount * bytesPerSample), to: &data)
        append(UInt16(channelCount * bytesPerSample), to: &data)
        append(UInt16(bitsPerSample), to: &data)
        data.append("data".data(using: .ascii) ?? Data())
        append(UInt32(dataByteCount), to: &data)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let envelope = amplitudeEnvelope(
                time: time,
                duration: effect.duration,
                decay: effect.decay
            )
            let mixedWave = effect.frequencies
                .map { sin(2 * Double.pi * $0 * time) }
                .reduce(0, +) / Double(effect.frequencies.count)
            let sparkle = deterministicNoise(at: index) * effect.noiseAmount
            let sampleValue = max(-1, min(1, (mixedWave + sparkle) * effect.amplitude * envelope))
            let sample = Int16(sampleValue * Double(Int16.max))
            append(sample, to: &data)
        }

        return data
    }

    private static func amplitudeEnvelope(time: Double, duration: Double, decay: Double) -> Double {
        let attack = min(1, time / 0.012)
        let release = min(1, max(duration - time, 0) / 0.045)
        let metallicDecay = exp(-time * decay)
        return attack * release * metallicDecay
    }

    private static func deterministicNoise(at index: Int) -> Double {
        let value = sin(Double(index) * 12.9898) * 43_758.5453
        return (value - floor(value)) * 2 - 1
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}
