//
//  SpeechManager.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechManager: NSObject, ObservableObject, SpeechManaging {
    @Published private(set) var isListening = false
    @Published private(set) var interimText = ""
    @Published private(set) var statusText = "대기 중"
    @Published private(set) var audioLevel: Double = 0

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var latestTranscriptionText = ""
    private var emittedCharacterCount = 0
    private var partialFinalizeTask: Task<Void, Never>?
    private var didRequestStop = false
    private var retryCount = 0

    var onFinalUtterance: ((String) -> Void)?

    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micGranted = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        statusText = speechGranted && micGranted ? "권한 허용됨" : "음성 인식/마이크 권한이 필요합니다"
        return speechGranted && micGranted
    }

    func start() async {
        retryCount = 0
        await startRecognition()
    }

    func stop() {
        didRequestStop = true
        retryCount = 0
        resetRecognition(finalizeInterim: true)
        statusText = "대기 중"
    }

    private func startRecognition() async {
        guard !isListening else { return }
        guard await requestPermissions() else { return }
        guard recognizer?.isAvailable == true else {
            statusText = "한국어 음성 인식기를 사용할 수 없습니다"
            return
        }

        resetRecognition(finalizeInterim: false)
        didRequestStop = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try configureRearFacingMicrophone(session)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
                let level = Self.normalizedAudioLevel(from: buffer)
                Task { @MainActor in
                    self.audioLevel = level
                }
            }

            audioEngine.prepare()
            try audioEngine.start()

            self.request = request
            isListening = true
            statusText = "대화를 듣는 중"

            task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    self?.handleRecognition(result: result, error: error)
                }
            }
        } catch {
            statusText = "음성 인식 시작 실패: \(error.localizedDescription)"
            resetRecognition(finalizeInterim: false)
        }
    }

    private func configureRearFacingMicrophone(_ session: AVAudioSession) throws {
        guard let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) else {
            return
        }

        try session.setPreferredInput(builtInMic)

        guard let rearDataSource = builtInMic.dataSources?.first(where: { $0.orientation == .back }) else {
            return
        }

        try builtInMic.setPreferredDataSource(rearDataSource)
    }

    private func resetRecognition(finalizeInterim: Bool) {
        partialFinalizeTask?.cancel()
        partialFinalizeTask = nil

        if finalizeInterim {
            emitPendingSegment(from: latestTranscriptionText)
        }

        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false
        interimText = ""
        audioLevel = 0
        latestTranscriptionText = ""
        emittedCharacterCount = 0
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error {
            handleRecognitionError(error)
            return
        }

        guard let result else { return }
        let fullText = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        latestTranscriptionText = fullText
        let pendingText = pendingSegment(from: fullText)
        interimText = pendingText

        partialFinalizeTask?.cancel()

        if result.isFinal {
            emitPendingSegment(from: fullText)
            interimText = ""
        } else if pendingText.count >= 3 {
            schedulePartialFinalize(for: fullText)
        }
    }

    private func schedulePartialFinalize(for fullText: String) {
        partialFinalizeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 850_000_000)
            guard !Task.isCancelled else { return }

            emitPendingSegment(from: fullText)
            interimText = ""
        }
    }

    private func emitPendingSegment(from fullText: String) {
        let pendingText = pendingSegment(from: fullText)
        guard finalize(pendingText) else { return }
        emittedCharacterCount = fullText.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private func pendingSegment(from fullText: String) -> String {
        let clean = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count > emittedCharacterCount else { return "" }

        let offset = min(emittedCharacterCount, clean.count)
        let startIndex = clean.index(clean.startIndex, offsetBy: offset)
        return clean[startIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleRecognitionError(_ error: Error) {
        guard !didRequestStop else { return }

        resetRecognition(finalizeInterim: false)

        if retryCount < 1 {
            retryCount += 1
            statusText = "음성 인식 재시도 중"
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                await startRecognition()
            }
            return
        }

        statusText = "음성 인식 오류: \(error.localizedDescription)"
    }

    private func finalize(_ text: String) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return false }

        onFinalUtterance?(clean)
        return true
    }

    private static func normalizedAudioLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<frameLength {
            let sample = channelData[index]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        guard rms > 0 else { return 0 }

        let decibels = 20 * log10(Double(rms))
        return min(1, max(0, (decibels + 55) / 55))
    }
}
