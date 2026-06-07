//
//  FaceTracker.swift
//  ZupZup
//
//  Created by Simon on 5/31/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import ImageIO
import Vision

struct FaceTrackingCandidate: Identifiable, Equatable {
    let id: UUID
    let faceCenter: CGPoint
    let mouthCenter: CGPoint
    let mouthPoints: [CGPoint]
    let mouthActivity: Double
    let speechScore: Double
    let speakerConfidence: Double
    let isLikelySpeaking: Bool
    let lastSeen: Date
}

struct FaceTrackingResult: Equatable {
    let capturedAt: Date
    let candidates: [FaceTrackingCandidate]

    var likelySpeaker: FaceTrackingCandidate? {
        candidates.first(where: \.isLikelySpeaking)
    }
}

final class FaceTracker: FaceTracking {
    private struct TrackedFace {
        var id: UUID
        var center: CGPoint
        var previousMouthActivity: Double
        var smoothedSpeechScore: Double
        var lastSeen: Date
    }

    private struct FaceDetection {
        let center: CGPoint
        let mouthCenter: CGPoint
        let mouthPoints: [CGPoint]
        let mouthActivity: Double
    }

    private var trackedFaces: [UUID: TrackedFace] = [:]

    func detectFaces(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .right
    ) -> FaceTrackingResult {
        let now = Date()
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let detections = observations.compactMap(makeDetection(from:))
            return updateTrackedFaces(with: detections, seenAt: now)
        } catch {
            return FaceTrackingResult(capturedAt: now, candidates: [])
        }
    }

    private func makeDetection(from observation: VNFaceObservation) -> FaceDetection? {
        guard let mouthActivity = mouthActivityScore(from: observation) else { return nil }
        let center = CGPoint(
            x: observation.boundingBox.midX,
            y: 1 - observation.boundingBox.midY
        )
        let mouthPoints = mouthLandmarkPoints(from: observation)
        let mouthCenter = centerPoint(for: mouthPoints) ?? CGPoint(
            x: center.x,
            y: min(0.98, center.y + observation.boundingBox.height * 0.18)
        )

        return FaceDetection(
            center: center,
            mouthCenter: mouthCenter,
            mouthPoints: mouthPoints,
            mouthActivity: mouthActivity
        )
    }

    private func updateTrackedFaces(
        with detections: [FaceDetection],
        seenAt now: Date
    ) -> FaceTrackingResult {
        var usedIDs = Set<UUID>()
        var candidates: [FaceTrackingCandidate] = []

        for detection in detections {
            let id = nearestTrackedFaceID(to: detection.center, excluding: usedIDs) ?? UUID()
            usedIDs.insert(id)

            var face = trackedFaces[id] ?? TrackedFace(
                id: id,
                center: detection.center,
                previousMouthActivity: detection.mouthActivity,
                smoothedSpeechScore: 0,
                lastSeen: now
            )

            let movementDelta = distance(face.center, detection.center) * 0.18
                + abs(detection.mouthActivity - face.previousMouthActivity) * 2.6
            let rawSpeechScore = min(1, detection.mouthActivity * 0.18 + movementDelta)
            let smoothed = face.smoothedSpeechScore * 0.58 + rawSpeechScore * 0.42

            face.center = detection.center
            face.previousMouthActivity = detection.mouthActivity
            face.smoothedSpeechScore = smoothed
            face.lastSeen = now
            trackedFaces[id] = face

            candidates.append(
                FaceTrackingCandidate(
                    id: id,
                    faceCenter: detection.center,
                    mouthCenter: detection.mouthCenter,
                    mouthPoints: detection.mouthPoints,
                    mouthActivity: detection.mouthActivity,
                    speechScore: smoothed,
                    speakerConfidence: 0,
                    isLikelySpeaking: false,
                    lastSeen: now
                )
            )
        }

        removeStaleFaces(now: now)

        let threshold = candidates.count <= 1 ? 0.12 : 0.15
        let likelySpeakerID = candidates.max { $0.speechScore < $1.speechScore }
            .flatMap { $0.speechScore >= threshold ? $0.id : nil }
        let sortedScores = candidates.map(\.speechScore).sorted(by: >)
        let topScore = sortedScores.first ?? 0
        let runnerUpScore = sortedScores.dropFirst().first ?? 0
        let speakerConfidence = min(1, max(0, topScore * 0.75 + (topScore - runnerUpScore) * 0.25))
        let resolvedCandidates = candidates.map { candidate in
            FaceTrackingCandidate(
                id: candidate.id,
                faceCenter: candidate.faceCenter,
                mouthCenter: candidate.mouthCenter,
                mouthPoints: candidate.mouthPoints,
                mouthActivity: candidate.mouthActivity,
                speechScore: candidate.speechScore,
                speakerConfidence: candidate.id == likelySpeakerID ? speakerConfidence : 0,
                isLikelySpeaking: candidate.id == likelySpeakerID,
                lastSeen: candidate.lastSeen
            )
        }

        return FaceTrackingResult(capturedAt: now, candidates: resolvedCandidates)
    }

    private func mouthActivityScore(from observation: VNFaceObservation) -> Double? {
        guard let landmarks = observation.landmarks else { return nil }

        let outer = normalizedHeightRatio(points: landmarks.outerLips?.normalizedPoints ?? [])
        let inner = normalizedHeightRatio(points: landmarks.innerLips?.normalizedPoints ?? [])
        let jawOpenness = max(outer, inner * 1.25)

        return min(1, max(0, jawOpenness * 2.1))
    }

    private func normalizedHeightRatio(points: [CGPoint]) -> Double {
        guard points.count >= 2 else { return 0 }

        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0

        let width = max(0.001, maxX - minX)
        let height = max(0, maxY - minY)

        return min(1, height / width)
    }

    private func mouthLandmarkPoints(from observation: VNFaceObservation) -> [CGPoint] {
        guard let landmarks = observation.landmarks else { return [] }

        let outer = landmarks.outerLips?.normalizedPoints ?? []
        let inner = landmarks.innerLips?.normalizedPoints ?? []
        let points = outer.isEmpty ? inner : outer + inner

        return points.map { point in
            let imageX = observation.boundingBox.minX + point.x * observation.boundingBox.width
            let imageY = observation.boundingBox.minY + point.y * observation.boundingBox.height
            return CGPoint(x: imageX, y: 1 - imageY)
        }
    }

    private func centerPoint(for points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }

        let total = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }

        return CGPoint(
            x: total.x / CGFloat(points.count),
            y: total.y / CGFloat(points.count)
        )
    }

    private func nearestTrackedFaceID(to center: CGPoint, excluding usedIDs: Set<UUID>) -> UUID? {
        trackedFaces
            .filter { !usedIDs.contains($0.key) }
            .map { (id: $0.key, distance: distance($0.value.center, center)) }
            .filter { $0.distance < 0.16 }
            .min { $0.distance < $1.distance }?
            .id
    }

    private func removeStaleFaces(now: Date) {
        trackedFaces = trackedFaces.filter { _, face in
            now.timeIntervalSince(face.lastSeen) < 1.3
        }
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> Double {
        let xDistance = lhs.x - rhs.x
        let yDistance = lhs.y - rhs.y
        return sqrt(Double(xDistance * xDistance + yDistance * yDistance))
    }
}
