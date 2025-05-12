import SwiftUI
import SwiftData

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingVoiceChat = false
    @State private var showingConversations = false
    @State private var selectedConversation: Conversation?
    @State private var isShowingNewConversation = false
    
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
                
                HStack {
                    TextField("Type a message...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isThinking)
                    
                    Button(action: {
                        showingVoiceChat = true
                    }) {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { 
                        if let conversation = selectedConversation {
                            viewModel.sendMessage(modelContext: modelContext, conversation: conversation)
                        } else {
                            // Create new conversation
                            let conversation = Conversation()
                            modelContext.insert(conversation)
                            selectedConversation = conversation
                            viewModel.sendMessage(modelContext: modelContext, conversation: conversation)
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
                }
                .padding()
            }
            .navigationTitle(selectedConversation?.title ?? "New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingConversations = true }) {
                        Image(systemName: "list.bullet")
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
