//
//  HandTracking.swift
//  ZupZup
//
//  Created by 조민지 on 5/30/26.
//

import Foundation
import Vision
import Observation
import CoreGraphics

// 손가락 제스처 상태
enum HandGestureState: Sendable {
    case none
    case pinched
    case apart
}

struct HandPoseResult: Sendable {
    let isHandDetected: Bool
    let gesture: HandGestureState
    let distance: CGFloat
    let indexTipPoint: CGPoint?
}


// 외부에서 관찰할 수 있는 핸드 트래킹 매니저 클래스
@MainActor
@Observable
final class HandTrackingManager {
    
    // 싱글톤 인스턴스 생성
    static let shared = HandTrackingManager()
    
    var currentGesture: HandGestureState = .none // 현재 손가락 제스처 상태 (초기값은 none)
    var distance: CGFloat = 0 // 엄지-검지 거리값
    var indexTipPoint : CGPoint? // 검지 끝 좌표
    var isHandDetected: Bool = false
    
    
    // 한번에 추적할 최대 손 개수 1개로 제한
    private init() {}
    
    
    // 실시간 카메라 화면(CVPixelBuffer)을 넘겨받아 처리할 함수
    nonisolated static func detectHandPose(from pixelBuffer: CVPixelBuffer) -> HandPoseResult {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        
        // 이미지 한 장으로 분석 시작하는 분석 핸들러
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )
        
        do {
            // 핸들러를 통해 요청서(request)를 실행(perform)
            try handler.perform([request])

            guard
                let observation = request.results?.first, // request의 결과중 첫 번째 손을 꺼내서 observation 변수에 담고
                let thumbTip = try? observation.recognizedPoint(.thumbTip), // 그 손에서 엄지 끝 좌표를 안전하게 추출
                let indexTip = try? observation.recognizedPoint(.indexTip), // 그 손에서 검지 끝 좌표도 안전하게 추출
                
                // 확신도가 30% 넘을 때만 아래로 통과시킴
                thumbTip.confidence > 0.3,
                indexTip.confidence > 0.3
            else {
                return HandPoseResult(
                    isHandDetected: false,
                    gesture: .none,
                    distance: 0,
                    indexTipPoint: nil
                )
                
            }

            let dx = thumbTip.location.x - indexTip.location.x
            let dy = thumbTip.location.y - indexTip.location.y
            let newDistance = sqrt(dx * dx + dy * dy) // 피타고라스 공식
            
            let gesture: HandGestureState
            
            if newDistance < 0.05 {
                gesture = .pinched
            } else if newDistance > 0.08 {
                gesture = .apart
            } else {
                gesture = .none
            }
            
            return HandPoseResult(
                isHandDetected: true,
                gesture: gesture,
                distance: newDistance,
                indexTipPoint: indexTip.location
            )
        } catch {
            return HandPoseResult(
                isHandDetected: false,
                gesture: .none,
                distance: 0,
                indexTipPoint: nil
            )
        }
    }
    
    func apply(_ result: HandPoseResult) {
        isHandDetected = result.isHandDetected
        distance = result.distance
        indexTipPoint = result.indexTipPoint
        
        if !result.isHandDetected {
            currentGesture = .none
            return
        }
        
        if result.distance < 0.05 {
            currentGesture = .pinched
        } else if result.distance > 0.08 {
            currentGesture = .apart
        }
    }
}
