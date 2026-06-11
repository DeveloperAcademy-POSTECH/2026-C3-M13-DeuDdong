//
//  ARDebugOverlayView.swift
//  ZupZup
//
//  Created by 조민지 on 6/1/26.
//

import SwiftUI

#if DEBUG
struct ARDebugOverlayView: View {
    let gesture: HandGestureState
    let distance: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gesture: \(gestureText)")
            Text("Distance: \(String(format: "%.3f", distance))")
        }
        .font(.caption)
        .padding(12)
        .background(Color.black.opacity(0.6))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var gestureText: String {
        switch gesture {
        case .none:
            return "None"
        case .pinched:
            return "pinched"
        case .apart:
            return "apart"
        }
    }
}

struct DeveloperDebugPanelView: View {
    let gesture: HandGestureState
    let distance: CGFloat
    let runtime: EmotionRuntime
    var testOrbAction: () -> Void
    var addOrbAction: () -> Void
    var addFiveOrbsAction: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                ARDebugOverlayView(gesture: gesture, distance: distance)
                MLDebugOverlayView(runtime: runtime)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 10) {
                Spacer(minLength: 0)
                HapticDebugView()
                Button("구슬 물리 테스트", action: testOrbAction)
                    .buttonStyle(.borderedProminent)
                debugOrbControls
            }
            .padding(.bottom, 78)
        }
    }

    private var debugOrbControls: some View {
        HStack(spacing: 8) {
            Button("구슬 +1", action: addOrbAction)
                .buttonStyle(.borderedProminent)
            Button("구슬 +5", action: addFiveOrbsAction)
                .buttonStyle(.bordered)
            Text("생성 제한 없음")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.45), in: Capsule())
    }
}
#endif

struct MLDebugOverlayView: View {
    let runtime: EmotionRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(runtime.speechState.isListening ? .red : .secondary)
                    .frame(width: 8, height: 8)

                Text(runtime.speechState.statusText)
                    .font(.caption.weight(.semibold))

                Spacer(minLength: 0)

                Text("구슬 \(runtime.emittedOrbEventCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            audioLevelBar

            Text(displayText)
                .font(.footnote)
                .lineLimit(2)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                labelChip(latestEmotionText)
                labelChip(faceTrackingText)
            }
        }
        .padding(14)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var audioLevelBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.28))

                Capsule()
                    .fill(.green)
                    .frame(width: max(4, proxy.size.width * runtime.speechState.audioLevel))
            }
        }
        .frame(height: 5)
    }

    private var displayText: String {
        if !runtime.speechState.interimText.isEmpty {
            return "인식 중: \(runtime.speechState.interimText)"
        }

        if !runtime.latestUtterance.isEmpty {
            return "최근 발화: \(runtime.latestUtterance)"
        }

        return "후면 카메라의 상대 발화를 기다리는 중"
    }

    private var latestEmotionText: String {
        guard let result = runtime.latestResult else {
            return "분류 대기"
        }

        if let emotion = result.emotion {
            return "\(emotion.koreanLabel) 생성"
        }

        return result.polarity.rawValue
    }

    private var faceTrackingText: String {
        guard let result = runtime.latestFaceTrackingResult else {
            return "얼굴 미확인"
        }

        if let speaker = result.likelySpeaker {
            return "화자 \(Int((speaker.speakerConfidence * 100).rounded()))%"
        }

        return "얼굴 \(result.candidates.count)명"
    }

    private func labelChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.24), in: Capsule())
    }
}
