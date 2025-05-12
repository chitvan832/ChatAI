import SwiftUI
import SwiftData

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingVoiceChat = false
    @State private var showingConversations = false
    @State private var selectedConversation: Conversation?
    @State private var isShowingNewConversation = false
    @FocusState private var isInputFocused: Bool
    
    init(apiKey: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack {
                        if let conversation = selectedConversation {
                            ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                MessageBubbleView(
                                    message: message,
                                    isSpeaking: viewModel.speakingMessageId == message.id,
                                    onCopy: { viewModel.copyToClipboard(message.content) },
                                    onToggleSpeech: { viewModel.toggleSpeech(for: message) }
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.immediately)
                
                HStack {
                    TextField("Ask anything", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...10)
                        .focused($isInputFocused)
                        .disabled(viewModel.isThinking)
                    
                    Button(action: {
                        showingVoiceChat = true
                    }) {
                        Image(systemName: SystemImage.waveForm.rawValue)
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        didTapSendButton()
                    }) {
                        Image(systemName: SystemImage.arrowUpCircleFill.rawValue)
                            .font(.title2)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
                }
                .padding()
                .background(Color.gray.opacity(0.3))
            }
            .navigationTitle(selectedConversation?.title ?? "New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingConversations = true }) {
                        Image(systemName: SystemImage.listBullet.rawValue)
                    }
                }
            }
            .overlay(alignment: .top) {
                if viewModel.showCopiedToast {
                    Text("Copied!")
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingConversations) {
                ConversationListView(
                    selectedConversation: $selectedConversation,
                    isShowingNewConversation: $isShowingNewConversation
                )
            }
            .sheet(isPresented: $showingVoiceChat) {
                RealTimeChatView(apiKey: viewModel.apiKey)
            }
            .onChange(of: isShowingNewConversation) { _, newValue in
                if newValue {
                    selectedConversation = nil
                    isShowingNewConversation = false
                }
            }
        }
    }
} 

extension ChatView {
    
    private func didTapSendButton() {
        isInputFocused = false
        
        viewModel.triggerHapticFeedback()
        
        if let conversation = selectedConversation {
            viewModel.sendMessage(modelContext: modelContext, conversation: conversation)
        } else {
            // Create new conversation
            let conversation = Conversation()
            modelContext.insert(conversation)
            selectedConversation = conversation
            viewModel.sendMessage(modelContext: modelContext, conversation: conversation)
        }
    }
}
