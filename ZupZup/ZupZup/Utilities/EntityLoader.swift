//
//  EntityLoader.swift
//  ZupZup
//

import RealityKit
import OSLog
import ZupZupContent

@MainActor
enum EntityLoader {
    private static var cache: [String: Entity] = [:]

    static func load(named name: String) async -> Entity? {
        if let cached = cache[name] {
            Logger.ar.info("'\(name)' 캐시 히트")
            return cached.clone(recursive: true)
        }
        let start = Date()
        do {
            let entity = try await Entity(named: name, in: ZupZupContentBundle)
            let elapsed = Date().timeIntervalSince(start) * 1000
            Logger.ar.info("'\(name)' 로드 완료: \(String(format: "%.1f", elapsed))ms")
            cache[name] = entity
            return entity.clone(recursive: true)
        } catch {
            Logger.ar.error("'\(name)' 로드 실패: \(error)")
            return nil
        }
    }
}
