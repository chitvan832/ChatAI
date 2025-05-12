//
//  VoiceInputManager.swift
//  ChatAI
//
//  Created by CS on 12/05/25.
//

import SwiftUI
import AVFoundation

class VoiceInputManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var volume: Float = 1.0
    @Published var transcribedText: String = ""
    @Published var streamingService = StreamingResponseService()
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let speechService: SpeechRecognitionService
    private let cohereService: CohereService
    
    init(apiKey: String) {
        self.speechService = SpeechRecognitionService()
        self.cohereService = CohereService(apiKey: apiKey)
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        do {
            try speechService.startRecording()
            isRecording = true
            
            // Start monitoring volume
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.volume = self.speechService.isRecording ? 1.0 : 0.0
                self.transcribedText = self.speechService.transcribedText
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        speechService.stopRecording()
        timer?.invalidate()
        timer = nil
        isRecording = false
        volume = 0
        
        // Start streaming response if we have transcribed text
        if !transcribedText.isEmpty {
            Task {
                await streamingService.startStreamingResponse(from: cohereService, prompt: transcribedText)
            }
        }
    }
}
