//
//  ARState.swift -> 앱 전체에서 공유되는 AR 상태값임
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import Foundation

enum ARState: Equatable {
    case searching
    case ready
    case unsupported
    
    var title: String {
        switch self {
        case .searching:
            "공간을 인식하는 중이에요."
        case .ready:
            "공간 인식을 완료했어요."
        case .unsupported:
            "해당 기기는 ARKit을 지원하지 않아요."
        }
    }
    
    var message: String {
        switch self {
        case .searching:
            "바닥을 천천히 비춰주세요."
        case .ready:
            ""
        case .unsupported:
            "ARKit을 지원하는 기기에서 실행해 주세요."
        }
    }
}
