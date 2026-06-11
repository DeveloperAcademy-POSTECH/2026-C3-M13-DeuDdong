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

            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 130)
                .padding(.top, 12)
                .padding(.bottom, 80)
            
            Text("보이지 않는 따뜻한 말을\n눈으로 담아보세요")
                .font(.system(size: 13, weight: .bold))
                .fontWeight(.bold)
                .foregroundStyle(ZZColor.brand300)
                .multilineTextAlignment(.center)
                .padding(.top, 130)
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
