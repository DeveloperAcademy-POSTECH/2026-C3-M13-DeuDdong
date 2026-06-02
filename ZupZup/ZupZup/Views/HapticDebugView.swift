//
//  HapticDebugView.swift
//  ZupZup
//
//  Created by 노을 on 5/31/26.
//

#if DEBUG
import SwiftUI

struct HapticDebugView: View {
    var body: some View {
        HStack(spacing: 12) {
            Button("1단계 햅틱") {
                HapticManager.shared.playSimple()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
    }
}
#endif
