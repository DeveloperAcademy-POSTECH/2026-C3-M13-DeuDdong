//
//  ReportSummary.swift
//  ZupZup
//

import Foundation

struct ReportSummary: Equatable {
    private(set) var emotionCounts: [EmotionType: Int] = [:]

    var totalCollectedCount: Int {
        EmotionType.allCases.reduce(0) { total, emotion in
            total + count(for: emotion)
        }
    }

    var maxEmotionCount: Int {
        EmotionType.allCases.map(count(for:)).max() ?? 0
    }

    var hasCollectedOrbs: Bool {
        totalCollectedCount > 0
    }

    mutating func record(_ emotion: EmotionType, count: Int = 1) {
        guard count > 0 else { return }
        emotionCounts[emotion, default: 0] += count
    }

    func count(for emotion: EmotionType) -> Int {
        emotionCounts[emotion, default: 0]
    }
}

extension ReportSummary {
    static var preview: ReportSummary {
        var summary = ReportSummary()
        summary.record(.gratitude, count: 3)
        summary.record(.empathy, count: 2)
        summary.record(.affection, count: 5)
        summary.record(.praise, count: 7)
        summary.record(.encouragement, count: 1)
        return summary
    }
}

#if DEBUG
extension ReportSummary {
    static var previewSamples: [ReportSummary] {
        previewCountSamples.map { counts in
            var summary = ReportSummary()

            for (emotion, count) in zip(EmotionType.allCases, counts) {
                summary.record(emotion, count: count)
            }

            return summary
        }
    }

    private static let previewCountSamples: [[Int]] = [
        [7, 2, 4, 5, 1],
        [1, 9, 2, 3, 6],
        [4, 1, 8, 2, 5],
        [2, 5, 1, 10, 3],
        [6, 3, 5, 1, 9],
        [3, 7, 2, 6, 4],
        [8, 4, 6, 2, 1],
        [1, 6, 3, 8, 5],
        [5, 2, 9, 4, 7],
        [4, 8, 1, 7, 2]
    ]
}
#endif
