import SwiftUI
import SwiftData
import UIKit

struct MessageBubbleView: View {
    let message: Message
    let isSpeaking: Bool
    let onCopy: () -> Void
    let onToggleSpeech: () -> Void
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if message.isUser {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
            } else {
                MarkdownTextView(text: message.content)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                
                MessageButtonsView(
                    message: message,
                    isSpeaking: isSpeaking,
                    onCopy: onCopy,
                    onToggleSpeech: onToggleSpeech
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.horizontal)
    }
} 

#Preview {
    VStack {
        MessageBubbleView(message: .init(content: "hello", role: .user),
                          isSpeaking: false,
                          onCopy: {},
                          onToggleSpeech: {})
        MessageBubbleView(message: .init(content: "hello **bold**\n\n1. First item\n2. Second item", role: .assistant),
                          isSpeaking: false,
                          onCopy: {},
                          onToggleSpeech: {})
    }
}
