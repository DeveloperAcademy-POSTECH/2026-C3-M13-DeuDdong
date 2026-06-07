//
//  ARStatusOverlayView.swift -> AR 상태 안내 UI(View)
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import SwiftUI

struct ARStatusOverlayView: View {
    let state: ARState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state == .ready ? "checkmark.circle.fill" : "viewfinder")
                .font(.title3)
                .foregroundStyle(state == .ready ? .green : .white)

            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.headline)

                if !state.message.isEmpty {
                    Text(state.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ARStatusOverlayView(state: .searching)
        .padding()
}
