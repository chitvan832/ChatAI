//
//  GoogleSpeechService 2.swift
//  ChatAI
//
//  Created by CS on 12/05/25.
//

import Foundation
import AVFoundation
import SwiftUI
import FirebaseVertexAI

final class GoogleSpeechService: NSObject, ObservableObject {
    enum State { case idle, listening, transcribing, speaking }

    @Published var state: State = .idle
    @Published var transcribedText: String = ""
    @Published var aiResponse: String = ""

    private let audioEngine = AVAudioEngine()
    private var audioBuffer = Data()

    // Vertex AI client and model
    private let vertex = VertexAI.vertexAI()
    private let model: GenerativeModel

    override init() {
        // Initialize the Vertex model (e.g., Gemini)
        self.model = VertexAI.vertexAI().generativeModel(modelName: "gemini-2.0-flash")
        super.init()
    }

    /// Call when user taps mic button to start recording
    public func startRecording() {
        guard state == .idle else { return }
        state = .listening
        audioBuffer.removeAll()

        // Configure and activate audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        let inputNode = audioEngine.inputNode
        // Use hardware sampling format to avoid format mismatch
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            // Extract raw audio bytes from AudioBufferList
            var audioBufferList = buffer.audioBufferList.pointee
            let buffers = UnsafeBufferPointer(start: &audioBufferList.mBuffers,
                                              count: Int(audioBufferList.mNumberBuffers))
            for buf in buffers {
                if let mData = buf.mData {
                    let data = Data(bytes: mData, count: Int(buf.mDataByteSize))
                    self.audioBuffer.append(data)
                }
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
            state = .idle
        }
    }

    /// Call when user taps mic button again to stop recording
    public func stopRecording() {
        guard state == .listening else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        state = .transcribing

        Task {
            await transcribeAudio()
        }
    }

    /// Streams transcription using FirebaseVertexAI
    private func transcribeAudio() async {
        do {
            // Prepare audio part (PCM data)
            let audio = InlineDataPart(data: audioBuffer, mimeType: "audio/wav")
            let prompt = "Transcribe what's said in this audio recording."
            var fullText = ""

            let stream = try model.generateContentStream(audio)
            for try await chunk in stream {
                if let text = chunk.text {
                    fullText += text
                    transcribedText = fullText
                }
            }

            // After transcription, generate AI response or echo
            aiResponse = "I heard you say: \(fullText)"
            state = .speaking
            speakResponse(aiResponse)
        } catch {
            print("Transcription error: \(error)")
            state = .idle
        }
    }

    /// Speaks the provided text using AVSpeechSynthesizer
    private func speakResponse(_ text: String) {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension GoogleSpeechService: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                  didFinish utterance: AVSpeechUtterance) {
        state = .idle
    }
}
