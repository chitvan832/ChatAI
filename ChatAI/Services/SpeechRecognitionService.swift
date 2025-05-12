//
//  SpeechRecognitionService.swift
//  ChatAI
//
//  Created by CS on 12/05/25.
//


import Foundation
import SwiftUI
import AVFoundation
import Speech

class SpeechRecognitionService: NSObject, ObservableObject {
    enum SpeechError: Error {
        case notAuthorized
        case recognitionUnavailable
    }

    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestAuthorization()
    }

    /// Request user permission for speech recognition
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }

    /// Start live speech-to-text recording
    func startRecording() throws {
        guard authorizationStatus == .authorized else {
            throw SpeechError.notAuthorized
        }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.recognitionUnavailable
        }
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Cancel existing task if running
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                // Update transcribed text
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }

        // Install tap on audio engine
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        DispatchQueue.main.async {
            self.isRecording = true
            self.transcribedText = ""
        }
    }

    /// Stop recording and end recognition
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // You can update UI based on availability if needed
    }
}
