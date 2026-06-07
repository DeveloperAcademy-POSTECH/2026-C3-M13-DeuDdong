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
        let start = Date()
        do {
            let entity = try await Entity(named: name, in: ZupZupContentBundle)
            let elapsed = Date().timeIntervalSince(start) * 1000
            Logger.arScene.info("'\(name)' 로드 완료: \(String(format: "%.1f", elapsed))ms")
            return entity
        } catch {
            Logger.arScene.error("'\(name)' 로드 실패: \(error)")
            return nil
        }
    }
}
