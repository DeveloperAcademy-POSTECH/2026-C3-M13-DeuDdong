import SwiftUI
import SpriteKit
import CoreMotion

// MARK: - SpriteKit Physics Scene
class OrbPhysicsScene: SKScene {
    private let motionManager = CMMotionManager()

    // 구슬 클릭 시 SwiftUI 레이어로 이벤트를 전달하기 위한 콜백
    var onOrbSelected: ((EmotionType) -> Void)?

    override func didMove(to view: SKView) {
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.friction = 0.3
        self.physicsBody?.restitution = 0.15
        self.backgroundColor = .clear

        let emotionTypes = EmotionType.allCases
        let orbSize: CGFloat = 90

        for (index, type) in emotionTypes.enumerated() {
            let orb = SKShapeNode(circleOfRadius: orbSize / 2)
            orb.fillColor = UIColor(type.swiftUIColor)
            orb.strokeColor = .white.withAlphaComponent(0.6)
            orb.lineWidth = 2.0

            // 터치 이벤트 발생 시 식별자로 사용하기 위해 name 속성 지정
            orb.name = type.rawValue

            let startX = CGFloat(60 + (index % 3) * 65)
            let startY = CGFloat(160 + (index / 3) * 100)
            orb.position = CGPoint(x: startX, y: startY)

            let physicsBody = SKPhysicsBody(circleOfRadius: orbSize / 2)
            physicsBody.isDynamic = true
            physicsBody.mass = 0.4
            physicsBody.friction = 0.25
            physicsBody.restitution = 0.25
            physicsBody.allowsRotation = true

            orb.physicsBody = physicsBody
            self.addChild(orb)
        }

        startMonitoringAcceleration()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let clickedNode = self.atPoint(location)

        // 클릭된 노드가 감정 구슬인 경우 처리
        if let nodeName = clickedNode.name, let emotion = EmotionType(rawValue: nodeName) {
            // 터치 피드백을 위한 순간적 튕김 물리 효과
            clickedNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))

            onOrbSelected?(emotion)
        }
    }

    // CoreMotion 가속도계를 활용한 실시간 중력 방향 업데이트
    private func startMonitoringAcceleration() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 60.0
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, _) in
                guard let self = self, let acceleration = data?.acceleration else { return }
                let gravityX = CGFloat(acceleration.x) * 9.8 * 2.3
                let gravityY = CGFloat(acceleration.y) * 9.8 * 2.3
                self.physicsWorld.gravity = CGVector(dx: gravityX, dy: gravityY)
            }
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - Main Home View
struct HomeView: View {
    var onStartConversation: () -> Void

    // 툴팁 노출 여부 및 데이터 매칭을 위한 상태 변수
    @State private var selectedEmotion: EmotionType?

    var orbScene: SKScene {
        let scene = OrbPhysicsScene()
        scene.size = CGSize(width: 250, height: 400)
        scene.scaleMode = .fill

        scene.onOrbSelected = { emotion in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                self.selectedEmotion = emotion
            }
        }
        return scene
    }

    var body: some View {
        ZStack {
            ZZColor.gray1.ignoresSafeArea()

            // 팝업 외부 영역 터치 시 닫기 레이어
            if selectedEmotion != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { selectedEmotion = nil }
                    }
            }

            VStack(spacing: 0) {
                Text("오늘도 따뜻한 대화를\n나누어보세요!")
                    .font(ZZFont.title)
                    .foregroundStyle(ZZColor.gray10)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 70)

                Spacer()

                // Container Graphic Area
                ZStack {
                    // 가상 유리병 아웃라인 플레이스홀더
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(ZZColor.gray3, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 8]))
                        .frame(width: 250, height: 400)
                        .background(ZZColor.gray0.opacity(0.5).clipShape(RoundedRectangle(cornerRadius: 32)))

                    SpriteView(scene: orbScene, options: [.allowsTransparency])
                        .frame(width: 250, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 32))

                    // Emotion Detail Tooltip Overlay
                    if let emotion = selectedEmotion {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("'\(emotion.title)'의 구슬")
                                    .font(ZZFont.smallCaption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(emotion.swiftUIColor)

                                Spacer()

                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(ZZColor.gray4)
                            }

                            Text(emotion.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ZZColor.gray8)
                                .lineSpacing(2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(width: 220) // 유리병 Bounds(250) 보안을 위한 고정 폭
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
                        .offset(y: -40) // 정중앙 구슬 무더기 위 안착을 위한 기본 오프셋 조율
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            withAnimation { selectedEmotion = nil }
                        }
                    }
                }
                .frame(height: 400)

                Spacer()

                VStack(spacing: 16) {
                    Text("기기를 기울여 구슬을 움직여보세요")
                        .font(ZZFont.smallCaption)
                        .foregroundStyle(ZZColor.gray5)

                    PrimaryButton(title: "대화 시작") {
                        onStartConversation()
                    }
                    .padding(.horizontal, ZZSpacing.screenHorizontal)
                }
                .padding(.bottom, 34)
            }
        }
    }
}

#Preview {
    HomeView(onStartConversation: {})
}
