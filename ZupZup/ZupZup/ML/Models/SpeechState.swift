//
//  SpeechState.swift
//  ZupZup
//
//  Created by Simon on 6/2/26.
//

import Foundation

struct SpeechState: Equatable {
    let isListening: Bool
    let interimText: String
    let statusText: String
    let audioLevel: Double
    let audioSamples: [Double]

    static let idle = SpeechState(
        isListening: false,
        interimText: "",
        statusText: "대기 중",
        audioLevel: 0,
        audioSamples: []
    )
}
