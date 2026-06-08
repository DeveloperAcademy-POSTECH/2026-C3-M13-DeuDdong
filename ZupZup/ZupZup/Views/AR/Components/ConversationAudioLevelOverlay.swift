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

struct VoiceWaveformView: View {
    let samples: [CGFloat]
    let strokeColor: Color

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                guard samples.count > 1 else { return }

                let midY = proxy.size.height / 2
                let stepX = proxy.size.width / CGFloat(samples.count - 1)

                for index in samples.indices {
                    let xPosition = CGFloat(index) * stepX
                    let amplitude = samples[index] * proxy.size.height * 0.45
                    let yPosition = midY - amplitude * sin(CGFloat(index) * 0.82)

                    if index == samples.startIndex {
                        path.move(to: CGPoint(x: xPosition, y: yPosition))
                    } else {
                        path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                    }
                }
            }
            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .shadow(color: strokeColor.opacity(0.35), radius: 6)
        }
        .frame(height: 96)
    }
}

struct MouthTrackingOverlay: View {
    let result: FaceTrackingResult?

    var body: some View {
        GeometryReader { proxy in
            ForEach(result?.candidates ?? []) { candidate in
                mouthPoints(for: candidate, in: proxy)
                mouthCenter(for: candidate, in: proxy)
            }
        }
        .allowsHitTesting(false)
    }

    private func mouthPoints(for candidate: FaceTrackingCandidate, in proxy: GeometryProxy) -> some View {
        ForEach(Array(candidate.mouthPoints.enumerated()), id: \.offset) { _, point in
            Circle()
                .fill(candidate.isLikelySpeaking ? ZZColor.brand400 : .white)
                .frame(width: candidate.isLikelySpeaking ? 7 : 5, height: candidate.isLikelySpeaking ? 7 : 5)
                .position(
                    x: point.x * proxy.size.width,
                    y: point.y * proxy.size.height
                )
        }
    }

    private func mouthCenter(for candidate: FaceTrackingCandidate, in proxy: GeometryProxy) -> some View {
        Circle()
            .stroke(candidate.isLikelySpeaking ? ZZColor.brand400 : .white.opacity(0.75), lineWidth: 2)
            .frame(width: 24, height: 24)
            .position(
                x: candidate.mouthCenter.x * proxy.size.width,
                y: candidate.mouthCenter.y * proxy.size.height
            )
    }
}
