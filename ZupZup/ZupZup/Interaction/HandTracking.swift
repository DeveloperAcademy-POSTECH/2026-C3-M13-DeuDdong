//
//  HandTracking.swift
//  ZupZup
//
//  Created by 조민지 on 5/30/26.
//

import Foundation
import Vision
import Observation

//손가락 제스처 상태
enum HandGestureState {
    case none
    case pinched
    case apart
}


//외부에서 관찰할 수 있는 핸드 트래킹 매니저 클래스
@Observable
final class HandTrackingManager {
    
    //싱글톤 인스턴스 생성
    static let shared = HandTrackingManager()
    
    var currentGesture: HandGestureState = .none //현재 손가락 제스처 상태 (초기값은 none)
    var distance: CGFloat = 0 //엄지-검지 거리값
    
    //손가락 감지 요청서 객체 생성
    private let request = VNDetectHumanHandPoseRequest()
    
    
    //한번에 추적할 최대 손 개수 1개로 제한
    private init() {
        request.maximumHandCount = 1
    }
    
    
    // 실시간 카메라 화면(CVPixelBuffer)을 넘겨받아 처리할 함수
    func updateHandPose(from pixelBuffer: CVPixelBuffer) {
        //이미지 한 장으로 분석 시작하는 분석 핸들러
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        do {
            //핸들러를 통해 요청서(request)를 실행(perform)
            try handler.perform([request])
            
            guard
                let observation = request.results?.first, //request의 결과중 첫 번째 손을 꺼내서 observation 변수에 담고
                let thumbTip = try?observation.recognizedPoint(.thumbTip), //그 손에서 엄지 끝 좌표를 안전하게 추출
                let indexTip = try?observation.recognizedPoint(.indexTip), //그 손에서 검지 끝 좌표도 안전하게 추출
                
                    //확신도가 30% 넘을 때만 아래로 통과시킴
                    thumbTip.confidence > 0.3,
                indexTip.confidence > 0.3
            else {
                currentGesture = .none
                return
            }
            
            let dx = thumbTip.location.x - indexTip.location.x
            let dy = thumbTip.location.y - indexTip.location.y
            
            let newDistance = sqrt(dx * dx + dy * dy) //피타고라스 공식
            
            distance = newDistance
            
            //계산된 거리로 제스처 상태 판정
            if newDistance < 0.05 {
                currentGesture = .pinched
            } else if newDistance > 0.08 {
                currentGesture = .apart
            }
            
        } catch {
            currentGesture = .none
        }
    }
    
}


