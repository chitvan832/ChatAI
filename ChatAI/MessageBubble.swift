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
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    MessageBubble(message: .init(content: "Hello",
                                 isUser: true))
        .modelContainer(for: Message.self)
}
