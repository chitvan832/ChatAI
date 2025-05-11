import Foundation
import SwiftUI
import SwiftData
import CoreHaptics

@MainActor
class ChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    @Published var currentStreamedText: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private var engine: CHHapticEngine?
    private let cohereService: CohereService
    
    init(apiKey: String) {
        cohereService = CohereService(apiKey: apiKey)
        prepareHaptics()
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
    
    func sendMessage(modelContext: ModelContext) {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create and save user message
        let userMessage = Message(content: inputText, role: .user)
        modelContext.insert(userMessage)
        
        // Trigger haptic feedback
        triggerHapticFeedback()
        
        // Clear input and show thinking state
        inputText = ""
        isThinking = true
        currentStreamedText = ""
        
        // Start streaming response
        Task {
            do {
                // Create initial empty assistant message for UI
                let assistantMessage = Message(content: "", role: .assistant)
                modelContext.insert(assistantMessage)
                
                // Get all messages for context, excluding the empty assistant message
                let messages = try modelContext.fetch(FetchDescriptor<Message>(sortBy: [SortDescriptor(\.timestamp)]))
                    .filter { $0.id != assistantMessage.id } // Exclude the empty assistant message
                
                // Start streaming
                var isFirstToken = true
                for try await token in try await cohereService.streamChatCompletion(messages: messages) {
                    if isFirstToken {
                        isFirstToken = false
                        isThinking = false
                        triggerHapticFeedback() // Second haptic feedback
                    }
                    
                    withAnimation(.easeIn) {
                        currentStreamedText += token
                        assistantMessage.content = currentStreamedText
                    }
                }
                
            } catch {
                isThinking = false
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}
