import SwiftUI
import UIKit

// Rich Text Editor with true formatting support
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var font: UIFont
    var textColor: UIColor
    var lineSpacing: CGFloat = 4
    var onTextViewCreated: ((UITextView) -> Void)?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        
        // Enable rich text editing
        textView.isSelectable = true
        textView.isEditable = true
        textView.allowsEditingTextAttributes = true
        
        // Apply paragraph style with line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        
        // Set default typing attributes
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
        
        // Configure text container
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.isScrollEnabled = true
        
        // Set initial attributed text
        textView.attributedText = attributedText
        
        // Notify parent about the text view
        DispatchQueue.main.async {
            onTextViewCreated?(textView)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if the text is different to avoid cursor jumping
        if !uiView.attributedText.isEqual(to: attributedText) {
            // Preserve selected range
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }
        
        // Update typing attributes for new text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        
        uiView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }
    }
}

// MARK: - Rich Text Formatting Toolbar

struct RichTextFormatToolbar: View {
    let onBold: () -> Void
    let onItalic: () -> Void
    let onUnderline: () -> Void
    let onStrikethrough: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Format buttons
                Button(action: onBold) {
                    Image(systemName: "bold")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                }
                
                Button(action: onItalic) {
                    Image(systemName: "italic")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                }
                
                Button(action: onUnderline) {
                    Image(systemName: "underline")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                }
                
                Button(action: onStrikethrough) {
                    Image(systemName: "strikethrough")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
        }
    }
}
