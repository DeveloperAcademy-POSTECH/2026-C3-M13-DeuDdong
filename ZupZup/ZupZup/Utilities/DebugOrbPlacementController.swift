//
//  DebugOrbPlacementController.swift
//  ZupZup
//

#if DEBUG
final class DebugOrbPlacementController {
    var trigger: (() -> Void)?

    func fire() {
        trigger?()
    }
}
#endif
