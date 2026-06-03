//
//  GridTexture.swift -> 그리드를 코드로 구성해둔 곳
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import RealityKit
import UIKit

enum GridTexture {
    static let resource: TextureResource = {
        let size = 256
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: {
                let format = UIGraphicsImageRendererFormat.default()
                format.opaque = false
                format.scale = 1
                return format
            }()
        )

        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
            cgContext.setStrokeColor(UIColor(white: 0.92, alpha: 0.95).cgColor)
            cgContext.setLineWidth(2)

            let cells = 8
            let step = CGFloat(size) / CGFloat(cells)

            for index in 0...cells {
                let point = CGFloat(index) * step
                cgContext.move(to: CGPoint(x: point, y: 0))
                cgContext.addLine(to: CGPoint(x: point, y: CGFloat(size)))
                cgContext.move(to: CGPoint(x: 0, y: point))
                cgContext.addLine(to: CGPoint(x: CGFloat(size), y: point))
            }

            cgContext.strokePath()
        }

        guard let cgImage = image.cgImage else {
            fatalError("Grid를 생성할 수 없어요.")
        }

        do {
            return try TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            )
        } catch {
            fatalError("Grid TextureResource 생성 실패: \(error)")
        }
    }()
}
