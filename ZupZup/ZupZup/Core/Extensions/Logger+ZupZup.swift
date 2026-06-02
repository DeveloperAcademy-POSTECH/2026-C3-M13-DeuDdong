//
//  Logger+ZupZup.swift
//  ZupZup
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "ZupZup"

    static let particle = Logger(subsystem: subsystem, category: "Particle")
    static let ar = Logger(subsystem: subsystem, category: "AR")
}
