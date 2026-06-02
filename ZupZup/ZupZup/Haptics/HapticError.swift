//
//  HapticError.swift
//  ZupZup
//
//  Created by 노을 on 5/30/26.
//

import Foundation

enum HapticError: LocalizedError {
    case notSupported
    case engineFailed
    case playFailed

    var errorDescription: String? {
        switch self {
        case .notSupported: return "이 기기는 햅틱을 지원하지 않아요"
        case .engineFailed: return "햅틱 엔진 시작에 실패했어요"
        case .playFailed: return "햅틱 재생에 실패했어요"
        }
    }
}
