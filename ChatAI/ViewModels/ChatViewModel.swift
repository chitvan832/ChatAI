import Foundation
import SwiftUI
import SwiftData
import CoreHaptics
import AVFoundation

@MainActor
class ChatViewModel: NSObject, ObservableObject {
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    @Published var currentStreamedText: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showCopiedToast: Bool = false
    @Published var speakingMessageId: UUID? = nil
    
    private var engine: CHHapticEngine?
    private let cohereService: CohereService
    private let synthesizer = AVSpeechSynthesizer()
    
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.cohereService = CohereService(apiKey: apiKey)
        super.init()
        prepareHaptics()
        synthesizer.delegate = self
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
    
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showCopiedToast = false
            }
        }
    }
    
    func toggleSpeech(for message: Message) {
        if speakingMessageId == message.id {
            synthesizer.stopSpeaking(at: .immediate)
            speakingMessageId = nil
        } else {
            let utterance = AVSpeechUtterance(string: message.content)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            synthesizer.stopSpeaking(at: .immediate)
            synthesizer.speak(utterance)
            speakingMessageId = message.id
        }
    }
    
    func sendMessage(modelContext: ModelContext, conversation: Conversation) {
        let userMessage = Message(content: inputText, role: .user)
        conversation.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if conversation.title == "New Chat" {
            conversation.updateTitle()
        }
        
        inputText = ""
        isThinking = true
        currentStreamedText = ""
        
        Task {
            do {
                // Create initial empty assistant message for UI
                let assistantMessage = Message(content: "", role: .assistant)
                conversation.messages.append(assistantMessage)
                
                // Filter out empty messages before sending to API
                let messagesForAPI = conversation.messages.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                
                // Start streaming
                var isFirstToken = true
                for try await token in try await cohereService.streamChatCompletion(messages: messagesForAPI) {
                    withAnimation(.easeIn) {
                        if isFirstToken {
                            triggerHapticFeedback()
                            isFirstToken = false
                        }
                        currentStreamedText += token
                        assistantMessage.content = currentStreamedText
                    }
                }
                isThinking = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isThinking = false
            }
        }
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

extension ChatViewModel: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speakingMessageId = nil
    }
}
