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
            Image("splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Text("zup\nzup")
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(ZZColor.brand400)
                .multilineTextAlignment(.center)
                .lineSpacing(-12)
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            onFinished()
        }
    }
}

#Preview {
    SplashView {}
}
