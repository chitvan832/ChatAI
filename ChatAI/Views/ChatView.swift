import SwiftUI
import SwiftData

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingVoiceChat = false
    
    init(apiKey: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(try! modelContext.fetch(FetchDescriptor<Message>(sortBy: [SortDescriptor(\.timestamp)]))) { message in
                            MessageBubbleView(
                                message: message,
                                isSpeaking: viewModel.speakingMessageId == message.id,
                                onCopy: { viewModel.copyToClipboard(message.content) },
                                onToggleSpeech: { viewModel.toggleSpeech(for: message) }
                            )
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
                    
                    Button(action: { viewModel.sendMessage(modelContext: modelContext) }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
                }
                .padding()
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
            .overlay {
                if viewModel.isThinking {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(isPresented: $showingVoiceChat) {
                RealTimeChatView(apiKey: Config.cohereAPIKey)
            }
        }
    }
} 
