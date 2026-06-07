//
//  OnboardingStep.swift
//  Zupzup
//
//  Created by Codex on 6/5/26.
//

import CoreGraphics

enum OnboardingStep: Int, CaseIterable {
    case serviceFlow = 1
    case orbDescription
    case permissions

    var progress: CGFloat {
        CGFloat(rawValue) / CGFloat(Self.allCases.count)
    }

    var previous: OnboardingStep? {
        Self(rawValue: rawValue - 1)
    }

    var next: OnboardingStep? {
        Self(rawValue: rawValue + 1)
    }
}
