//
//  OrbitingLinesView.swift
//  ChatAI
//
//  Created by CS on 12/05/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            SmoothRotatingCircle(trimEnd: 1, color: .green, speed: 60,
            width: 250)
            SmoothRotatingCircle(trimEnd: 1, color: .orange, speed: -90, width: 200)
            SmoothRotatingCircle(trimEnd: 1, color: .blue, speed: -60, width: 150)
            SmoothRotatingCircle(trimEnd: 1, color: .red, speed: 90,
            width: 250)

            Text("Listening...")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(width: 250, height: 250)
    }
}



struct SmoothRotatingCircle: View {
    @State private var rotation: Double = 0
    @State private var timer: Timer? = nil

    var trimEnd: CGFloat
    var color: Color
    var speed: Double
    var width: CGFloat = 200
    var axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (1, 1, 0)

    var body: some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(color, lineWidth: 10)
            .frame(width: width, height: 200)
            .rotation3DEffect(.degrees(rotation), axis: axis)
            .onAppear {
                startRotation()
            }
            .onDisappear {
                stopRotation()
            }
    }

    private func startRotation() {
        stopRotation()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            rotation += speed * 0.01
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopRotation() {
        timer?.invalidate()
        timer = nil
    }
}


struct OrbitingLinesView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
