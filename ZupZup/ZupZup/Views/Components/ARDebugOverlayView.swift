//
//  ARDebugOverlayView.swift
//  ZupZup
//
//  Created by 조민지 on 6/1/26.
//

import SwiftUI

#if DEBUG
struct ARDebugOverlayView: View {
    let gesture: HandGestureState
    let distance: CGFloat

    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gesture: \(gestureText)")
            Text("Distance: \(String(format: "%.3f", distance))")
        }
        .font(.caption)
        .padding(12)
        .background(Color.black.opacity(0.6))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var gestureText: String {
        switch gesture {
        case .none:
            return "None"
        case .pinched:
            return "pinched"
        case .apart:
            return "apart"
        }
    }
}
#endif

//#Preview {
//    ARDebugOverlayView()
//}
