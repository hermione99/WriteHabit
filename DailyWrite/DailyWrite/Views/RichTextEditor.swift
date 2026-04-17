import SwiftUI
import UIKit

// Rich Text Editor with true formatting support
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var font: UIFont
    var textColor: UIColor
    var lineSpacing: CGFloat = 4
    var onTextViewCreated: ((UITextView) -> Void)?
    var onTextChange: (() -> Void)?  // Real-time callback for word count
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        
        // Enable rich text editing
        textView.isSelectable = true
        textView.isEditable = true
        textView.allowsEditingTextAttributes = true
        
        // Configure text container
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.isScrollEnabled = true
        
        // Set initial text without heavy formatting (fast path)
        // Formatting will be applied asynchronously
        textView.attributedText = attributedText
        textView.textColor = textColor
        
        // Apply typing attributes for new text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
        
        // Defer heavy font formatting to background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let mutableAttrText = NSMutableAttributedString(attributedString: self.attributedText)
            let fullRange = NSRange(location: 0, length: mutableAttrText.length)
            
            if fullRange.length > 0 {
                // Apply font to entire text
                mutableAttrText.addAttribute(.font, value: self.font, range: fullRange)
                
                // Update paragraph style while preserving alignment
                mutableAttrText.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                    let newParagraphStyle = NSMutableParagraphStyle()
                    if let existingStyle = value as? NSParagraphStyle {
                        // Copy all properties including alignment from existing
                        newParagraphStyle.setParagraphStyle(existingStyle)
                    }
                    // Update only line spacing
                    newParagraphStyle.lineSpacing = self.lineSpacing
                    newParagraphStyle.paragraphSpacing = self.lineSpacing * 0.5
                    mutableAttrText.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                }
                
                mutableAttrText.addAttribute(.foregroundColor, value: self.textColor, range: fullRange)
                
                // Update on main thread
                DispatchQueue.main.async {
                    let selectedRange = textView.selectedRange
                    textView.attributedText = mutableAttrText
                    textView.selectedRange = selectedRange
                }
            }
        }
        
        // Notify parent about the text view
        DispatchQueue.main.async {
            onTextViewCreated?(textView)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Check if font or line spacing changed by comparing with coordinator's stored values
        let coordinator = context.coordinator
        let fontChanged = coordinator.currentFont?.fontName != font.fontName || coordinator.currentFont?.pointSize != font.pointSize
        let lineSpacingChanged = abs(coordinator.currentLineSpacing - lineSpacing) > 0.1
        
        // Update paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        
        // Get current paragraph alignment to preserve it for new text
        let currentAlignment: NSTextAlignment
        let cursorLocation = uiView.selectedRange.location
        if cursorLocation < uiView.attributedText.length {
            if let style = uiView.attributedText.attribute(.paragraphStyle, at: cursorLocation, effectiveRange: nil) as? NSParagraphStyle {
                currentAlignment = style.alignment
            } else {
                currentAlignment = .left
            }
        } else {
            currentAlignment = .left
        }
        
        // Update paragraph style with current alignment
        paragraphStyle.alignment = currentAlignment
        
        // Always update typing attributes for new text
        uiView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
        uiView.textColor = textColor
        
        // Only update text content if it changed from external source (not from user typing)
        // Compare hash of text content to avoid expensive updates on every keystroke
        let textChanged = uiView.attributedText.string != attributedText.string
        
        if textChanged && !coordinator.isUpdating {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }
        
        // If font or line spacing changed, update the entire text
        if fontChanged || lineSpacingChanged {
            // Create updated attributed text with new font and line spacing
            let mutableAttrText = NSMutableAttributedString(attributedString: uiView.attributedText)
            let fullRange = NSRange(location: 0, length: mutableAttrText.length)
            
            if fullRange.length > 0 {
                // Update font for the entire text
                mutableAttrText.addAttribute(.font, value: font, range: fullRange)
                
                // Update paragraph style while preserving alignment
                // Enumerate existing paragraph styles and update only line spacing
                mutableAttrText.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                    let newParagraphStyle = NSMutableParagraphStyle()
                    if let existingStyle = value as? NSParagraphStyle {
                        // Copy all properties including alignment
                        newParagraphStyle.setParagraphStyle(existingStyle)
                    }
                    // Update only line spacing
                    newParagraphStyle.lineSpacing = lineSpacing
                    newParagraphStyle.paragraphSpacing = lineSpacing * 0.5
                    mutableAttrText.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                }
                
                // Update foreground color
                mutableAttrText.addAttribute(.foregroundColor, value: textColor, range: fullRange)
                
                // Preserve selected range
                let selectedRange = uiView.selectedRange
                uiView.attributedText = mutableAttrText
                uiView.selectedRange = selectedRange
                
                // Update the parent's attributedText to match without triggering another update
                DispatchQueue.main.async {
                    coordinator.isUpdating = true
                    self.attributedText = mutableAttrText
                    coordinator.isUpdating = false
                }
            }
            
            // Update coordinator's stored values
            coordinator.currentFont = font
            coordinator.currentLineSpacing = lineSpacing
        } else if !uiView.attributedText.isEqual(to: attributedText) {
            // Only update if the text is different (from external changes)
            // and we're not currently in the middle of an update
            if !context.coordinator.isUpdating {
                let selectedRange = uiView.selectedRange
                uiView.attributedText = attributedText
                uiView.selectedRange = selectedRange
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isUpdating = false
        var currentFont: UIFont?
        var currentLineSpacing: CGFloat = 4
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
            self.currentFont = parent.font
            self.currentLineSpacing = parent.lineSpacing
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if !isUpdating {
                parent.attributedText = textView.attributedText
                // Call real-time callback for word count update
                parent.onTextChange?()
            }
        }
    }
}

// MARK: - Rich Text Formatting Toolbar

struct RichTextFormatToolbar: View {
    let onBold: () -> Void
    let onItalic: () -> Void
    let onUnderline: () -> Void
    let onStrikethrough: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Format buttons with theme color icons
                Button(action: onBold) {
                    Image(systemName: "bold")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(themeManager.accent)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onItalic) {
                    Image(systemName: "italic")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(themeManager.accent)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onUnderline) {
                    Image(systemName: "underline")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(themeManager.accent)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onStrikethrough) {
                    Image(systemName: "strikethrough")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(themeManager.accent)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.ultraThinMaterial)
        }
    }
}
