//
//  AR_.swift
//  ZupZup
//
//  Created by Kimseoyeon on 6/5/26.
//


import SwiftUI

struct ARCollectView: View {
    
    @Binding private var currentOrbCount: Int
    let totalOrbCount: Int
    var onReturnHome: () -> Void = {}
    var onCompleted: () -> Void = {}
    
    
    @State private var showTutorialOverlay = true
    @State private var animateHand = false
    
    @State private var showTipModal = false
    @State private var currentTipPage = 0
    
    @State private var tipModalOffset: CGFloat = 700
    @State private var tipModalOpacity: Double = 0
    
    @State private var showAutoCollectView = false
    @State private var showCollectCompletedView = false
    @State private var showCompletionPhase = false

    init(
        currentOrbCount: Binding<Int> = .constant(0),
        totalOrbCount: Int = 0,
        onReturnHome: @escaping () -> Void = {},
        onCompleted: @escaping () -> Void = {}
    ) {
        self._currentOrbCount = currentOrbCount
        self.totalOrbCount = totalOrbCount
        self.onReturnHome = onReturnHome
        self.onCompleted = onCompleted
    }
    
    var body: some View {
        
        
        if showAutoCollectView {
            
            AutoCollectView {

                withAnimation(.easeInOut(duration: 0.2)) {
                    showAutoCollectView = false
                    showCompletionPhase = true
                }
            }
            .zIndex(200)
        }
        
        else if showCompletionPhase {
            Color.clear
            CollectionCompleteOverlay(
                reportAction: {
                    onCompleted()
                }
            )
            
        }
        else {
            ZStack {
                // MARK: AR Layer
                
                Color.clear
                
                // MARK: Orb Count
                
                VStack(spacing: 12) {
                    
                    OrbCountCapsule(
                        current: currentOrbCount,
                        total: totalOrbCount,
                        isComplete: totalOrbCount > 0 && currentOrbCount == totalOrbCount
                    )
                    
                    AutoCollectButton {
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAutoCollectView = true
                        }
                    }.padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.top, 78)
                .zIndex(1)
                
                // MARK: Tutorial Overlay
                
                if showTutorialOverlay {
                    
                    ZStack {
                        
                        ZZColor.gray9
                            .opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack {
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                
                                Text("대화가 종료되었습니다")
                                    .font(ZZFont.headline)
                                    .foregroundStyle(.white)
                                
                                Text("구슬 수집을 시작합니다")
                                    .font(ZZFont.title)
                                    .foregroundStyle(.white)
                            }
                            
                            Spacer()
                                .frame(height: 48)
                            
                            ZStack {
                                
                                Image("ARCollect_iphone")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 240)
                                
                                Image("ARCollect_hand")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150)
                                    .offset(
                                        x: animateHand ? 70 : 50,
                                        y: animateHand ? -45 : -25
                                    )
                                    .rotationEffect(
                                        .degrees(animateHand ? -3 : 3)
                                    )
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                        value: animateHand
                                    )
                            }
                            
                            Spacer()
                                .frame(height: 24)
                            
                            Text("손가락으로 구슬을 집어서\n유리병에 넣어보세요")
                                .font(ZZFont.subheadline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.top, 24)
                            Spacer()
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTutorialOverlay = false
                        }
                    }
                    .onAppear {
                        animateHand = true
                    }
                    .zIndex(10)
                }
                
                // MARK: Tip Modal
                
                if showTipModal || tipModalOpacity > 0 {
                    
                    ZStack(alignment: .bottom) {
                        
                        // 배경
                        
                        ZZColor.gray9
                            .opacity(0.5 * tipModalOpacity)
                            .ignoresSafeArea()
                            .onTapGesture {
                                
                                withAnimation(.easeIn(duration: 0.18)) {
                                    
                                    tipModalOffset = 700
                                    tipModalOpacity = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    
                                    showTipModal = false
                                }
                            }
                        // 카드 시트
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ZZColor.gray4)
                                .frame(width: 36, height: 4)
                                .padding(.top, 12)
                            Text("구슬 수집 방법")
                                .font(ZZFont.headline)
                                .foregroundStyle(ZZColor.gray10)
                                .padding(.top, 20)
                            TabView(selection: $currentTipPage) {
                                
                                OnboardingCardView(
                                    title: "",
                                    description: "AR상 주변 공간을 비춰\n구슬을 확인합니다"
                                ) {
                                    
                                    Image("ARCollect_Tip1")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                }
                                .tag(0)
                                
                                OnboardingCardView(
                                    title: "",
                                    description: "손으로 AR상 구슬을\n집어 올립니다"
                                ) {
                                    
                                    Image("ARCollect_Tip2")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                }
                                .tag(1)
                                
                                OnboardingCardView(
                                    title: "",
                                    description: "구슬을 AR상 병에\n넣습니다"
                                ) {
                                    
                                    Image("ARCollect_Tip3")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                }
                                .tag(2)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 470)
                            
                            HStack(spacing: 8) {
                                
                                ForEach(0..<3, id: \.self) { index in
                                    
                                    Circle()
                                        .fill(
                                            currentTipPage == index
                                            ? ZZColor.gray10
                                            : ZZColor.gray4
                                        )
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .background(ZZColor.gray0)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 24,
                                style: .continuous
                            )
                        )
                        .offset(y: tipModalOffset)
                        .opacity(tipModalOpacity)
                    }
                    .zIndex(50)
                }
                
                // MARK: Home Button
                
                VStack {
                    
                    HStack {
                        
                        ARHomeButtonDark {
                            onReturnHome()
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 78)
                .zIndex(100)
                
                // MARK: Help Button
                
                if tipModalOpacity == 0 {
                    
                    VStack {
                        
                        Spacer()
                        
                        HStack {
                            
                            ARHelpButton {
                                
                                showTipModal = true
                                
                                withAnimation(.easeOut(duration: 0.22)) {
                                    
                                    tipModalOffset = 0
                                    tipModalOpacity = 1
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 50)
                    .zIndex(100)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                
                tipModalOffset = 700
                tipModalOpacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    
    ZStack {
        
        Color.black
            .ignoresSafeArea()
        
        ARCollectView()
    }
}
