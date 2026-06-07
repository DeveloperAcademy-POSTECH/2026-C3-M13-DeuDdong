//
//  EntityLoaderTests.swift
//  ZupZupTests
//

import XCTest
@testable import ZupZup

final class EntityLoaderTests: XCTestCase {

    @MainActor func testEntityLoadTime() async {
        let name = EmotionType.praise.particleName

        let start1 = Date()
        _ = await EntityLoader.load(named: name)
        let first = Date().timeIntervalSince(start1) * 1000
        print("첫 번째 로드: \(String(format: "%.1f", first))ms")

        let start2 = Date()
        _ = await EntityLoader.load(named: name)
        let second = Date().timeIntervalSince(start2) * 1000
        print("두 번째 로드: \(String(format: "%.1f", second))ms")
    }
}
