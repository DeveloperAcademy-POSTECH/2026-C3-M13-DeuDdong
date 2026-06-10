//
//  FeedbackSoundPlayer.swift
//  ZupZup
//

import AudioToolbox
import Foundation

enum FeedbackSoundPlayer {
    private enum SoundID {
        static let countdownTick: SystemSoundID = 1104
        static let orbDrop: SystemSoundID = 1306
        static let orbCollision: SystemSoundID = 1057
        static let particleBurst: SystemSoundID = 1157
    }

    static func playCountdownTick() {
        play(SoundID.countdownTick)
    }

    static func playOrbDrop() {
        play(SoundID.orbDrop)
    }

    static func playOrbCollision() {
        play(SoundID.orbCollision)
    }

    static func playParticleBurst() {
        play(SoundID.particleBurst)
    }

    private static func play(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
