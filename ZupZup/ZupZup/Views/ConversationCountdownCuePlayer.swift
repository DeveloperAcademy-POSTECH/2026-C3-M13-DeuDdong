//
//  ConversationCountdownCuePlayer.swift
//  ZupZup
//
//  Created by Codex on 6/5/26.
//

import AVFoundation
import AudioToolbox

@MainActor
final class ConversationCountdownCuePlayer {
    private let synthesizer = AVSpeechSynthesizer()

    func speakIntro() {
        guard !synthesizer.isSpeaking else { return }

        let utterance = AVSpeechUtterance(string: "잠시 후 대화가 시작됩니다")
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.46
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    func playTick() {
        AudioServicesPlaySystemSound(1104)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
