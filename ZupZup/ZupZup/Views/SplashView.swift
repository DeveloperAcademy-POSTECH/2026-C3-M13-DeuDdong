//
//  SplashView.swift
//  ZupZup
//
//  Created by Simon on 6/4/26.
//

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            ZZColor.gray0.ignoresSafeArea()

            Text("zup\nzup")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(ZZColor.brand400)
                .multilineTextAlignment(.center)
                .lineSpacing(-8)
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onFinished()
        }
    }
}

#Preview {
    SplashView {}
}
