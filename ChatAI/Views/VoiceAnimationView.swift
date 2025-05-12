import SwiftUI

struct VoiceAnimationView: View {
    let isSpeaking: Bool
    let volume: Float
    let isAIResponding: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var equalizerHeight: CGFloat = 0
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if isAIResponding {
                // Equalizer animation
                EqualizerView(height: equalizerHeight)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
    }
}

struct YarnBallView: View {
    let rotation: Double
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .rotation3DEffect(.degrees(rotation + Double(index) * 45), axis: (x: 1, y: 1, z: 0))
            }
        }
        .scaleEffect(scale)
    }
}

struct EqualizerView: View {
    let height: CGFloat
    
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
        .stroke(Color.blue, lineWidth: 3)
    }
} 