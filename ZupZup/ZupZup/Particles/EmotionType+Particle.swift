//
//  EmotionType+Particle.swift
//  ZupZup
//

import Foundation

extension EmotionType {
    var particleName: String {
        switch self {
        case .praise:       "Particles/PraiseParticle"
        case .encouragement: "Particles/EncouragementParticle"
        case .affection:    "Particles/AffectionParticle"
        case .gratitude:    "Particles/GratitudeParticle"
        case .empathy:      "Particles/EmpathyParticle"
        }
    }
}
