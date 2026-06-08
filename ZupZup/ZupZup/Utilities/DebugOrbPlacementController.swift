//
//  DebugOrbPlacementController.swift
//  ZupZup
//

final class OrbEventPlacementController {
    var trigger: ((EmotionOrbEvent) -> Void)?

    func fire(_ event: EmotionOrbEvent) {
        trigger?(event)
    }
}

#if DEBUG
final class DebugOrbPlacementController {
    var trigger: ((Int) -> Void)?

    func fire(count: Int = 1) {
        trigger?(count)
    }
}
#endif
