//
//  EntityLoader.swift
//  ZupZup
//

import RealityKit
import OSLog
import ZupZupContent

@MainActor
enum EntityLoader {
    static func load(named name: String) async -> Entity? {
        do {
            return try await Entity(named: name, in: ZupZupContentBundle)
        } catch {
            Logger.ar.error("'\(name)' 로드 실패: \(error)")
            return nil
        }
    }
}
