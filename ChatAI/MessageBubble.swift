//
//  MessageBubble.swift
//  ChatAI
//
//  Created by CS on 11/05/25.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            if message.isUser {
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            } else {
                Group {
                    if let attributedString = try? AttributedString(markdown: message.content) {
                        Text(attributedString)
                    } else {
                        Text(message.content)
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(20)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}
//
//#Preview {
//    MessageBubble(message: .init(content: "Hello",
//                                 isUser: true))
//        .modelContainer(for: Message.self)
//}
