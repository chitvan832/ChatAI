import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.timestamp) private var messages: [Message]
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var textEditorHeight: CGFloat = 36
    
    private let maxTextEditorHeight: CGFloat = 120
    private let minTextEditorHeight: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isThinking {
                                ThinkingBubble()
                                    .id("thinking")
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isThinking) { _, isThinking in
                        if isThinking {
                            withAnimation {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 8) {
                        // Dynamic height TextEditor
                        TextEditor(text: $viewModel.inputText)
                            .frame(height: max(minTextEditorHeight, min(textEditorHeight, maxTextEditorHeight)))
                            .padding(8)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.onChange(of: geo.size.height) { _, newHeight in
                                        textEditorHeight = newHeight
                                    }
                                }
                            )
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                            .focused($isInputFocused)
                        
                        Button(action: {
                            viewModel.sendMessage(modelContext: modelContext)
                            isInputFocused = false
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
            }
            .onTapGesture {
                isInputFocused = false
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
            
            if !message.isUser { Spacer() }
        }
    }
}

private struct ThinkingBubble: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
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
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ChatView()
        .modelContainer(for: Message.self)
} 