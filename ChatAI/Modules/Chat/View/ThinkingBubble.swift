//
//  ThinkingBubble.swift
//  ChatAI
//
//  Created by CS on 11/05/25.
//

import SwiftUI

struct ThinkingBubble: View {
    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 18)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(0.2 * Double(index)),
                            value: isAnimating
                        )
                }
            }
            .padding(12)
            .background(
                    Color.gray.opacity(0.2)
            )
            .cornerRadius(20)
            .redacted(reason: .placeholder)
            .modifier(Shimmer())
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
}

#Preview {
    ThinkingBubble()
}
