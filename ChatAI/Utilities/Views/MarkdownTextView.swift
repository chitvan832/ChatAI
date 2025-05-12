import SwiftUI

struct MarkdownTextView: View {
    let text: String
    
    private var attributedString: AttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            var attributedString = try AttributedString(markdown: text, options: options)
            
            // Apply custom styling
            attributedString.foregroundColor = .primary
            attributedString.font = .body
            
            // Handle lists and paragraphs
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 8
            paragraphStyle.lineSpacing = 4
            
            // Apply paragraph style to the entire string
            attributedString.paragraphStyle = paragraphStyle
            
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
    
    var body: some View {
        Text(attributedString)
            .textSelection(.enabled)
    }
} 