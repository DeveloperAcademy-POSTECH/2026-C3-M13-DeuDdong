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
        case countdownTick
        case orbDrop
        case orbCollision
        case particleBurst

        var frequencies: [Double] {
            switch self {
            case .countdownTick:
                [880]
            case .orbDrop:
                [420, 560]
            case .orbCollision:
                [190, 260]
            case .particleBurst:
                [740, 980, 1_220]
            }
        }

        var duration: Double {
            switch self {
            case .countdownTick:
                0.08
            case .orbDrop:
                0.12
            case .orbCollision:
                0.10
            case .particleBurst:
                0.18
            }
        }

        var amplitude: Double {
            switch self {
            case .countdownTick:
                0.28
            case .orbDrop:
                0.20
            case .orbCollision:
                0.32
            case .particleBurst:
                0.24
            }
        }
    }

    private static var players: [Effect: AVAudioPlayer] = [:]
    private static var isAudioSessionPrepared = false

    static func prepare() {
        prepareAudioSessionIfNeeded()
        for effect in [Effect.countdownTick, .orbDrop, .orbCollision, .particleBurst] {
            _ = player(for: effect)
        }
    }

    static func playCountdownTick() {
        play(.countdownTick)
    }

    static func playOrbDrop() {
        play(.orbDrop)
    }

    static func playOrbCollision() {
        play(.orbCollision)
    }

    static func playParticleBurst() {
        play(.particleBurst)
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
            let data = wavData(for: effect)
            let player = try AVAudioPlayer(data: data)
            player.volume = 1
            player.prepareToPlay()
            players[effect] = player
            return player
        } catch {
            Logger.haptic.error("피드백 사운드 준비 실패: \(error.localizedDescription, privacy: .public)")
            return nil
        }
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
            let envelope = amplitudeEnvelope(time: time, duration: effect.duration)
            let mixedWave = effect.frequencies
                .map { sin(2 * Double.pi * $0 * time) }
                .reduce(0, +) / Double(effect.frequencies.count)
            let sample = Int16(mixedWave * effect.amplitude * envelope * Double(Int16.max))
            append(sample, to: &data)
        }

        return data
    }

    private static func amplitudeEnvelope(time: Double, duration: Double) -> Double {
        let attack = min(1, time / 0.012)
        let release = min(1, max(duration - time, 0) / 0.035)
        return min(attack, release)
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}
