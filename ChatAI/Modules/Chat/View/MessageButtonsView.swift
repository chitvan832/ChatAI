import SwiftUI
import SwiftData

struct MessageButtonsView: View {
    let message: Message
    let isSpeaking: Bool
    let onCopy: () -> Void
    let onToggleSpeech: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Button(action: onToggleSpeech) {
                Label(isSpeaking ? "Pause" : "Play", systemImage: isSpeaking ? "pause.circle" : "speaker.wave.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
} 