import CoreMotion
import SpriteKit
import SwiftUI

struct ReportGravityBowlView: View {
    let items: [EmotionReportItem]

    @State private var selectedEmotion: EmotionType?

    private let sceneSize = CGSize(width: 250, height: 300)
    private var selectedItem: EmotionReportItem? {
        guard let selectedEmotion else { return nil }
        return items.first { $0.type == selectedEmotion }
    }

    var body: some View {
        ZStack {
            Image("EmptyBallGlass")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 450)

            SpriteView(scene: scene, options: [.allowsTransparency])
                .frame(width: sceneSize.width, height: sceneSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 60))
                .padding(.top, 120)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image("EmptyBallGlass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text("수집된 구슬이 없어요")
                        .font(ZZFont.caption)
                        .foregroundStyle(ZZColor.gray5)
                }
                .offset(y: 64)
            }

            if let selectedItem {
                emotionTooltip(for: selectedItem)
                    .offset(y: -112)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        withAnimation { selectedEmotion = nil }
                    }
            }
        }
        .frame(width: 350, height: 450)
    }

    private var scene: SKScene {
        let scene = ReportGravityBowlScene(items: items, size: sceneSize)
        scene.onOrbSelected = { emotion in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedEmotion = emotion
                }
            }
        }
        return scene
    }

    private func emotionTooltip(for item: EmotionReportItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("'\(item.type.title)'의 구슬")
                    .font(ZZFont.smallCaption)
                    .fontWeight(.bold)
                    .foregroundStyle(item.type.swiftUIColor)

                Spacer()

                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ZZColor.gray4)
            }

            Text("\(item.count)개 수집됨 · \(item.type.description)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ZZColor.gray8)
                .lineSpacing(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 220)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
    }
}

private final class ReportGravityBowlScene: SKScene {
    private let items: [EmotionReportItem]
    private let motionManager = CMMotionManager()
    private var hasConfigured = false

    var onOrbSelected: ((EmotionType) -> Void)?

    init(items: [EmotionReportItem], size: CGSize) {
        self.items = items
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        configureIfNeeded()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        guard let selectedNode = nodes(at: location).first(where: { emotion(from: $0) != nil }),
              let emotion = emotion(from: selectedNode)
        else {
            return
        }

        physicsNode(from: selectedNode)?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 18))
        onOrbSelected?(emotion)
    }

    private func configureIfNeeded() {
        guard !hasConfigured else { return }
        hasConfigured = true

        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -2.8)
        addBottleBoundary()
        addReportOrbs()
        startMonitoringAcceleration()
    }

    private func addBottleBoundary() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.15
    }

    private func addReportOrbs() {
        for (index, item) in items.enumerated() {
            let orb = SKSpriteNode(imageNamed: item.type.imageName)
            orb.size = CGSize(width: item.size, height: item.size)
            orb.position = startPosition(for: index, item: item)
            orb.zPosition = CGFloat(index)
            orb.name = item.type.rawValue

            let body = SKPhysicsBody(circleOfRadius: item.size * 0.42)
            body.isDynamic = true
            body.allowsRotation = true
            body.mass = max(0.2, item.size / 180)
            body.friction = 0.25
            body.restitution = 0.22
            body.linearDamping = 0.28
            body.angularDamping = 0.9
            orb.physicsBody = body

            addInfoLabels(to: orb, item: item)
            addChild(orb)
        }
    }

    private func startPosition(for index: Int, item: EmotionReportItem) -> CGPoint {
        let slots: [CGFloat] = [0.22, 0.5, 0.78, 0.34, 0.66]
        let slot = slots[index % slots.count]
        let radius = item.size / 2
        let positionX = min(max(size.width * slot, radius), size.width - radius)
        let positionY = min(size.height - radius, 170 + CGFloat(index / 3) * 96)
        return CGPoint(x: positionX, y: positionY)
    }

    private func addInfoLabels(to orb: SKSpriteNode, item: EmotionReportItem) {
        let titleLabel = makeLabel(
            text: item.type.compactTitle,
            fontSize: min(16, max(10, item.size * 0.15)),
            positionY: item.size * 0.08,
            emotion: item.type
        )
        let countLabel = makeLabel(
            text: "\(item.count)개",
            fontSize: min(18, max(12, item.size * 0.18)),
            positionY: -item.size * 0.12,
            emotion: item.type
        )

        orb.addChild(titleLabel)
        orb.addChild(countLabel)
    }

    private func makeLabel(
        text: String,
        fontSize: CGFloat,
        positionY: CGFloat,
        emotion: EmotionType
    ) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.name = emotion.rawValue
        label.fontName = "AppleSDGothicNeo-Bold"
        label.fontSize = fontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: positionY)
        label.zPosition = 1
        return label
    }

    private func emotion(from node: SKNode) -> EmotionType? {
        var currentNode: SKNode? = node

        while let node = currentNode {
            if let name = node.name,
               let emotion = EmotionType(rawValue: name) {
                return emotion
            }

            currentNode = node.parent
        }

        return nil
    }

    private func physicsNode(from node: SKNode) -> SKNode? {
        var currentNode: SKNode? = node

        while let node = currentNode {
            if node.physicsBody != nil {
                return node
            }

            currentNode = node.parent
        }

        return nil
    }

    private func startMonitoringAcceleration() {
        guard motionManager.isAccelerometerAvailable else {
            return
        }

        motionManager.accelerometerUpdateInterval = 1.0 / 60.0

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self,
                  let acceleration = data?.acceleration
            else {
                return
            }

            self.physicsWorld.gravity = CGVector(
                dx: CGFloat(acceleration.x) * 9.8 * 2.3,
                dy: CGFloat(acceleration.y) * 9.8 * 2.3
            )
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

#Preview {
    ReportGravityBowlView(items: ReportView.reportItems(from: .preview))
        .background(ZZColor.gray1)
}
