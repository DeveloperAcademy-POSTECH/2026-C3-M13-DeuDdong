//
//  Logger.swift
//  ZupZup
//
//  Created by 노을 on 6/5/26.
//

import OSLog

extension Logger {
    static let particle = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ZupZup", category: "Particle")
    static let haptic = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ZupZup", category: "Haptic")
    static let ar = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ZupZup", category: "AR")
}
