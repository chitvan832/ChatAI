////
////  ReactiveCircleView.swift
////  ChatAI
////
////  Created by CS on 12/05/25.
////

import SwiftUI

struct ReactiveCircleView: View {
    @ObservedObject var viewModel: ReactiveCircleViewModel

    let trimEnd: CGFloat
    let color: Color
    let width: CGFloat
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (1, 1, 0)

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(color.opacity(viewModel.isListening ? 1.0 : 0.8), lineWidth: 8)
            .frame(width: width, height: 200)
            .scaleEffect(viewModel.scale)
            .rotation3DEffect(.degrees(viewModel.rotationAngle), axis: axis)
    }
}

class ReactiveCircleViewModel: ObservableObject {
    
    @Published var rotationAngle: Double = 0
    @Published var scale: CGFloat = 1.0

    var isListening: Bool = false {
        didSet { updateTargets() }
    }

    private var speed: Double = 10
    private var targetSpeed: Double = 10
    private var targetScale: CGFloat = 1.0

    private var baseSpeed: Double = 10
    private var activeSpeed: Double = 50

    private var timer: Timer?

    func configure(baseSpeed: Double, activeSpeed: Double) {
        self.baseSpeed = baseSpeed
        self.activeSpeed = activeSpeed
        self.speed = baseSpeed
        self.targetSpeed = baseSpeed
        self.targetScale = 1.0
        self.rotationAngle = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            self.stepAnimation()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stepAnimation() {
        let easing = 0.05
        speed += (targetSpeed - speed) * easing
        scale += (targetScale - scale) * easing
        rotationAngle += speed / 60.0
    }

    private func updateTargets() {
        targetSpeed = isListening ? activeSpeed : baseSpeed
        targetScale = isListening ? 1.2 : 1.0
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }
}

struct ReactiveCircleView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceAnimationView(isListening: .constant(true))
    }
}
