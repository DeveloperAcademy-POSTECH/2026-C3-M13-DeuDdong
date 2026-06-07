//
//  DebugBurstController.swift
//  ZupZup
//

#if DEBUG
final class DebugBurstController {
    var trigger: (() -> Void)?

    func fire() {
        trigger?()
    }
}
#endif
