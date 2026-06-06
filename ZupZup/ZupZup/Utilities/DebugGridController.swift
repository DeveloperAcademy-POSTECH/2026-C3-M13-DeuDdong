//
//  DebugGridController.swift
//  ZupZup
//

#if DEBUG
final class DebugGridController {
    var toggle: (() -> Bool)?

    func toggleVisibility() -> Bool {
        toggle?() ?? true
    }
}
#endif
