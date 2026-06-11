//
//  DesignSystem.swift
//  Zupzup
//
//  Created by Kimseoyeon on 6/3/26.
//

import SwiftUI

enum ZZColor {
    static let brand0 = Color(hex: 0xFFE3D6)
    static let brand100 = Color(hex: 0xFFC1A3)
    static let brand200 = Color(hex: 0xFF9E70)
    static let brand300 = Color(hex: 0xFF7C3D)
    static let brand400 = Color(hex: 0xFF590A)
    static let brand500 = Color(hex: 0xD64500)
    static let brand600 = Color(hex: 0xA33500)
    static let brand700 = Color(hex: 0x702400)
    static let brand800 = Color(hex: 0x3D1400)
    static let brand900 = Color(hex: 0x0A0300)

    static let gray0 = Color(hex: 0xF9FAFB)
    static let gray1 = Color(hex: 0xF3F4F6)
    static let gray2 = Color(hex: 0xE5E7EB)
    static let gray3 = Color(hex: 0xD1D5DC)
    static let gray4 = Color(hex: 0x99A1AF)
    static let gray5 = Color(hex: 0x6A7282)
    static let gray6 = Color(hex: 0x4B5565)
    static let gray7 = Color(hex: 0x364153)
    static let gray8 = Color(hex: 0x1E2939)
    static let gray9 = Color(hex: 0x101828)
    static let gray10 = Color(hex: 0x030712)

    static let emotionRed = Color(hex: 0xF77D7D)
    static let emotionYellow = Color(hex: 0xF7E37D)
    static let emotionGreen = Color(hex: 0x94E67A)
    static let emotionBlue = Color(hex: 0x7DBEF7)
    static let emotionPurple = Color(hex: 0xC27DF7)

    static let dim = gray9.opacity(0.8)
}

enum ZZFont {
    static let title = Font.system(size: 26, weight: .bold)
    static let headline = Font.system(size: 24, weight: .bold)
    static let subheadline = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 18, weight: .medium)
    static let caption = Font.system(size: 16, weight: .medium)
    static let smallCaption = Font.system(size: 14, weight: .medium)
}

enum ZZSpacing {
    static let screenHorizontal: CGFloat = 22
    static let bottomButtonHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 8
    static let cardCornerRadius: CGFloat = 24
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
