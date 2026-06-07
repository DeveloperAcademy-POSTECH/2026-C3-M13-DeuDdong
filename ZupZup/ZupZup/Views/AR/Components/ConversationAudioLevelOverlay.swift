//
//  ConversationAudioLevelOverlay.swift
//  ZupZup
//
//  Created by Codex on 6/5/26.
//

import SwiftUI

struct ConversationAudioLevelOverlay: View {
    let speechState: SpeechState

    private let lowAudioThreshold = 0.18

    var body: some View {
        VStack(spacing: 12) {
            VoiceWaveformView(samples: waveformSamples, strokeColor: waveformColor)
                .padding(.horizontal, -20)

            if shouldShowLowAudioWarning {
                StatusToast(
                    text: "조금 더 크게 대화 해주세요",
                    systemName: "exclamationmark.circle.fill",
                    isWarning: true
                )
                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .transition(.opacity)
            }
        }
    }

    private var shouldShowLowAudioWarning: Bool {
        speechState.isListening && speechState.audioLevel < lowAudioThreshold
    }

    private var waveformColor: Color {
        shouldShowLowAudioWarning ? ZZColor.brand400 : .white
    }

    private var waveformSamples: [CGFloat] {
        let level = max(0.04, min(1.0, speechState.audioLevel))
        return (0..<36).map { index in
            let phase = CGFloat(index) * 0.62
            let wave = (sin(phase) + 1) / 2
            let pulse = (index % 5 == 0) ? CGFloat(0.22) : CGFloat(0.08)
            return min(1, CGFloat(level) * (0.35 + wave * 0.65) + pulse)
        }
    }
}
