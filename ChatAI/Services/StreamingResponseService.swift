import Foundation
import AVFoundation
import SwiftUI

class StreamingResponseService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var isSpeaking = false
    @Published var currentResponse = ""
    
    private var synthesizer: AVSpeechSynthesizer?
    private var responseTask: Task<Void, Never>?
    private var tokenBuffer = ""
    private var lastSpokenTime: Date = .now
    
    override init() {
        super.init()
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
    }
    
    func startStreamingResponse(from cohereService: CohereService, prompt: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        currentResponse = ""
        
        // Cancel any existing response
        responseTask?.cancel()
        
        // Create new response task
        responseTask = Task {
            do {
                for try await token in try await cohereService.streamChatCompletion(messages: [
                    Message(content: prompt, role: .user)
                ]) {
                    guard !Task.isCancelled else { break }
                    
                    await MainActor.run {
                        currentResponse += token
                        handleStreamingToken(token)
                    }
                }
            } catch {
                print("Error streaming response: \(error)")
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    func stopStreaming() {
        responseTask?.cancel()
        synthesizer?.stopSpeaking(at: .immediate)
        isProcessing = false
        isSpeaking = false
        currentResponse = ""
    }
    
    private func handleStreamingToken(_ token: String) {
        tokenBuffer += token
        lastSpokenTime = .now

        if token.hasSuffix(".") || token.hasSuffix("?") || token.hasSuffix("!") {
            speakBufferedText()
        }
    }

    private func speakBufferedText() {
        guard !tokenBuffer.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: tokenBuffer.trimmingCharacters(in: .whitespacesAndNewlines))
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer?.speak(utterance)
        tokenBuffer = ""
    }
}

extension StreamingResponseService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
} 
