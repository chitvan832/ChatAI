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
            
            HStack(alignment: .bottom, spacing: 8) {
                // Dynamic height TextField
                TextField("Describe yourself", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...10)
                    .focused($isInputFocused)
                    .background(Color.gray.opacity(0.1))
                
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
            .background(Color(UIColor.systemBackground))
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
}

#Preview {
    ChatView()
        .modelContainer(for: Message.self)
}

//// UIViewRepresentable wrapper to create a growing UITextView
//struct GrowingTextView: UIViewRepresentable {
//    @Binding var text: String
//    @Binding var dynamicHeight: CGFloat
//    let maxHeight: CGFloat
//
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.isScrollEnabled = false          // disable scrolling until exceeding maxHeight
//        textView.font = UIFont.preferredFont(forTextStyle: .body)
//        textView.delegate = context.coordinator
//        textView.backgroundColor = .clear
//        textView.textContainerInset = .zero
//        textView.textContainer.lineFragmentPadding = 0
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        if uiView.text != text {
//            uiView.text = text
//        }
//        DispatchQueue.main.async {
//            let size = uiView.sizeThatFits(
//                CGSize(width: uiView.frame.size.width, height: .greatestFiniteMagnitude)
//            )
//            // Constrain to maxHeight
//            let height = min(size.height, maxHeight)
//            if dynamicHeight != height {
//                dynamicHeight = height
//            }
//            // Enable scrolling when content exceeds maxHeight
//            uiView.isScrollEnabled = size.height > maxHeight
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(text: $text)
//    }
//
//    class Coordinator: NSObject, UITextViewDelegate {
//        @Binding var text: String
//        init(text: Binding<String>) {
//            _text = text
//        }
//        func textViewDidChange(_ textView: UITextView) {
//            text = textView.text
//        }
//    }
//}
//
//struct ChatView: View {
//    @State private var messages: [Message] = []
//    @State private var inputText: String = ""
//    @State private var inputHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight + 16
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Chat scroll area
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 8) {
//                        ForEach(messages) { msg in
//                            HStack {
//                                if msg.isUser { Spacer() }
//                                Text(msg.text)
//                                    .padding(12)
//                                    .background(msg.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
//                                    .cornerRadius(12)
//                                if !msg.isUser { Spacer() }
//                            }
//                            .id(msg.id)
//                        }
//                    }
//                    .padding()
//                }
//                .onAppear {
//                    // Scroll to bottom on load
//                    if let last = messages.last {
//                        proxy.scrollTo(last.id, anchor: .bottom)
//                    }
//                }
//                .onChange(of: messages.count) { _ in
//                    // Scroll to bottom when new message arrives
//                    withAnimation {
//                        if let last = messages.last {
//                            proxy.scrollTo(last.id, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//
//            Divider()
//
//            // Input area
//            HStack(alignment: .bottom) {
//                GrowingTextView(
//                    text: $inputText,
//                    dynamicHeight: $inputHeight,
//                    maxHeight: lineHeight() * 10  // limit to 10 lines
//                )
//                .frame(height: inputHeight)
//                .padding(8)
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(8)
//
//                Button(action: sendMessage) {
//                    Image(systemName: "paperplane.fill")
//                        .font(.system(size: 24))
//                }
//                .padding(.leading, 8)
//            }
//            .padding()
//            // Keep above the keyboard
//            .background(Color(UIColor.systemBackground).ignoresSafeArea(.keyboard))
//        }
//    }
//
//    private func lineHeight() -> CGFloat {
//        UIFont.preferredFont(forTextStyle: .body).lineHeight
//    }
//
//    private func sendMessage() {
//        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        messages.append(Message(text: trimmed, isUser: true))
//        inputText = ""
//        inputHeight = lineHeight() + 16  // reset to one line + padding
//        // TODO: Trigger haptic feedback and Thinking bubble, then call LLM...
//    }
//}
//
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView()
//    }
//}
