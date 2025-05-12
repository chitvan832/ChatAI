import SwiftUI

struct VoiceAnimationView: View {
    let isSpeaking: Bool
    let volume: Float
    let isAIResponding: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var equalizerHeight: CGFloat = 0
    @State private var isTransitioning: Bool = false
    @State private var linePositions: [CGPoint] = []
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    private let numberOfLines = 4
    
    var body: some View {
        ZStack {
            conditionalView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .onChange(of: isAIResponding) { _, newValue in
            if newValue {
                updateLinePositions()
            }
        }
    }
    
    private var conditionalView: some View {
        Group {
            if isAIResponding {
                // Animated lines
                ForEach(0..<numberOfLines, id: \.self) { index in
                    AnimatedLine(
                        startPoint: linePositions[safe: index] ?? .zero,
                        height: equalizerHeight * CGFloat(index + 1) / CGFloat(numberOfLines),
                        delay: Double(index) * 0.1
                    )
                }
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        equalizerHeight = CGFloat(volume) * 100
                    }
                }
            } else {
                // Yarn ball animation
                YarnBallView(rotation: rotation, scale: scale)
                    .onReceive(timer) { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            rotation += isSpeaking ? 2 : 0.5
                            scale = isSpeaking ? 1.2 : 1.0
                        }
                    }
            }
        }
    }
    
    private func updateLinePositions() {
        let arr = [0, 1, 2, 3]
        var newPositions: [CGPoint] = []

        for i in arr {
            let degrees = Double(i) * 45 + rotation
            let radians = degrees * .pi / 180
            let radius = 50.0 * scale
            let centerX = UIScreen.main.bounds.width / 2
            let centerY = UIScreen.main.bounds.height / 2
            let x = centerX + cos(radians) * radius
            let y = centerY + sin(radians) * radius

            newPositions.append(CGPoint(x: x, y: y))
        }

        linePositions = newPositions
    }
}

struct YarnBallView: View {
    let rotation: Double
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 5)
                    .frame(width: 100, height: 100)
                    .rotation3DEffect(.degrees(rotation + Double(index) * 45), axis: (x: 1, y: 1, z: 0))
            }
        }
        .scaleEffect(scale)
    }
}

struct AnimatedLine: View {
    let startPoint: CGPoint
    let height: CGFloat
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Path { path in
            let width = UIScreen.main.bounds.width - 40
            let centerY = UIScreen.main.bounds.height / 2
            
            path.move(to: CGPoint(x: 20, y: centerY))
            path.addQuadCurve(
                to: CGPoint(x: width + 20, y: centerY),
                control: CGPoint(x: width/2 + 20, y: centerY - height)
            )
        }
        .stroke(Color.blue.opacity(0.3), lineWidth: 3)
        .offset(x: isAnimating ? 0 : -UIScreen.main.bounds.width)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
