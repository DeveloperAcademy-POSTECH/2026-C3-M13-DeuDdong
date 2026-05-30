//
//  HapticManager.swift
//  ZupZup
//
//  Created by 노을 on 5/30/26.
//

import CoreHaptics

class HapticManager {
    // 앱 전체에서 하나의 인스턴스만 사용 (싱글톤)
    static let shared = HapticManager()

    // Taptic Engine을 제어하는 객체. 옵셔널인 이유는 초기화 실패 시 nil이 될 수 있어서
    private var engine: CHHapticEngine?

    // 초기화 실패 시 에러를 저장해두는 변수. 재생 시점에 꺼내서 던짐
    private var engineError: HapticError?

    private init() {
        // 기기가 햅틱을 지원하는지 확인 (시뮬레이터, 구형 기기는 미지원)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            engineError = .notSupported
            return
        }
        do {
            // 엔진 생성 — 내부적으로 오디오 세션을 점유함
            engine = try CHHapticEngine()

            // 전화, 백그라운드 전환 등으로 엔진이 멈췄을 때 호출되는 핸들러
            // 현재는 별도 처리 없이 넘어감
            engine?.stoppedHandler = { _ in }

            // OS가 오디오 세션을 돌려준 뒤 엔진을 리셋할 때 호출되는 핸들러
            // 자동으로 재시작해서 이후 햅틱이 정상 동작하도록 함
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }

            // 엔진 시작 — 이 시점부터 햅틱 재생 가능
            try engine?.start()
        } catch {
            engineError = .engineFailed
        }
    }

    func playSimple() throws {
        // 초기화 실패 에러가 저장돼 있으면 그대로 던짐
        if let engineError { throw engineError }
        // 엔진이 없으면 재생 불가
        guard let engine else { throw HapticError.engineFailed }

        // 햅틱 이벤트 정의
        // .hapticTransient — 순간적인 진동 (탭, 클릭 느낌)
        // intensity: 진동 세기 (0.0 ~ 1.0)
        // sharpness: 진동 질감. 0이면 묵직하고, 1이면 날카로움 (0.0 ~ 1.0)
        // relativeTime: player.start() 기준으로 몇 초 후에 실행할지
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        do {
            // 이벤트 → 패턴 → 플레이어 순서로 만들어야 재생 가능 (CoreHaptics 고정 구조)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            throw HapticError.playFailed
        }
    }

    func playFold() throws {
        if let engineError { throw engineError }
        guard let engine else { throw HapticError.engineFailed }

        // 첫 번째 이벤트: 약하고 둔한 진동 — 뭔가 잡히는 느낌
        let grab = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0
        )
        // 두 번째 이벤트: 강하고 묵직한 진동 — 0.15초 후에 쾅 접히는 느낌
        let collapse = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.15
        )
        do {
            let pattern = try CHHapticPattern(events: [grab, collapse], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            throw HapticError.playFailed
        }
    }
}
