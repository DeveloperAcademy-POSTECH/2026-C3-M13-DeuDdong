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
    private let visibleSampleCount = 54

    var body: some View {
        VStack(spacing: 10) {
            if shouldShowLowAudioWarning {
                StatusToast(
                    text: "조금 더 크게 대화 해주세요",
                    systemName: "exclamationmark.circle.fill",
                    isWarning: true
                )
                .padding(.horizontal, ZZSpacing.screenHorizontal)
                .transition(.opacity)
            }

            VoiceWaveformView(
                samples: waveformSamples,
                strokeColor: waveformColor
            )
            .padding(.horizontal, 12)
            .transition(.opacity)
        }
        .animation(.easeOut(duration: 0.12), value: speechState.audioSamples)
        .animation(.easeOut(duration: 0.2), value: shouldShowLowAudioWarning)
    }

    private var shouldShowLowAudioWarning: Bool {
        speechState.isListening && speechState.audioLevel < lowAudioThreshold
    }

    private var waveformColor: Color {
        shouldShowLowAudioWarning ? ZZColor.brand400 : .white
    }

    private var waveformSamples: [CGFloat] {
        let samples = speechState.audioSamples
            .suffix(visibleSampleCount)
            .map { CGFloat(max(0.03, min(1.0, $0))) }
        let missingSampleCount = max(0, visibleSampleCount - samples.count)
        return Array(repeating: CGFloat(0.03), count: missingSampleCount) + samples
    }
}

private struct VoiceWaveformView: View {
    let samples: [CGFloat]
    let strokeColor: Color

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 3
            let count = max(samples.count, 1)
            let barWidth = max(2, (proxy.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))

            ZStack {
                Rectangle()
                    .fill(strokeColor.opacity(0.28))
                    .frame(height: 1)

                HStack(alignment: .center, spacing: spacing) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                        Capsule()
                            .fill(strokeColor.opacity(opacity(for: index)))
                            .frame(
                                width: barWidth,
                                height: max(3, normalized(sample) * proxy.size.height)
                            )
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 88)
        .drawingGroup()
    }

    private func normalized(_ sample: CGFloat) -> CGFloat {
        let scaledSample = pow(max(0.03, min(1, sample)), 0.78)
        return 0.12 + scaledSample * 0.88
    }

    private func opacity(for index: Int) -> Double {
        let denominator = max(samples.count - 1, 1)
        let progress = Double(index) / Double(denominator)
        return 0.32 + progress * 0.68
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
