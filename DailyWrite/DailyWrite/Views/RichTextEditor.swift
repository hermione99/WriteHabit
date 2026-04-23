import SwiftUI
import UIKit

// Rich Text Editor with true formatting support
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var font: UIFont
    var textColor: UIColor
    var lineSpacing: CGFloat = 4
    var onTextViewCreated: ((UITextView) -> Void)?
    var onTextChange: (() -> Void)?
    var toolbarHostingController: UIHostingController<RichTextFormatToolbar>?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        
        textView.isSelectable = true
        textView.isEditable = true
        textView.allowsEditingTextAttributes = true
        
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.isScrollEnabled = true
        textView.keyboardDismissMode = .interactive // Enable dismissible keyboard
        
        textView.attributedText = attributedText
        textView.textColor = textColor
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
        
        setupToolbar(for: textView, context: context)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let mutableAttrText = NSMutableAttributedString(attributedString: self.attributedText)
            let fullRange = NSRange(location: 0, length: mutableAttrText.length)
            
            if fullRange.length > 0 {
                mutableAttrText.addAttribute(.font, value: self.font, range: fullRange)
                
                mutableAttrText.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                    let newParagraphStyle = NSMutableParagraphStyle()
                    if let existingStyle = value as? NSParagraphStyle {
                        newParagraphStyle.setParagraphStyle(existingStyle)
                    }
                    newParagraphStyle.lineSpacing = self.lineSpacing
                    newParagraphStyle.paragraphSpacing = self.lineSpacing * 0.5
                    mutableAttrText.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                }
                
                mutableAttrText.addAttribute(.foregroundColor, value: self.textColor, range: fullRange)
                
                DispatchQueue.main.async {
                    let selectedRange = textView.selectedRange
                    textView.attributedText = mutableAttrText
                    textView.selectedRange = selectedRange
                }
            }
        }
        
        DispatchQueue.main.async {
            onTextViewCreated?(textView)
        }
        
        return textView
    }
    
    private func setupToolbar(for textView: UITextView, context: Context) {
        let toolbar = RichTextFormatToolbar(
            onBold: { context.coordinator.applyBold(to: textView) },
            onItalic: { context.coordinator.applyItalic(to: textView) },
            onUnderline: { context.coordinator.applyUnderline(to: textView) },
            onStrikethrough: { context.coordinator.applyStrikethrough(to: textView) },
            onAlignLeft: { context.coordinator.applyAlignment(.left, to: textView) },
            onAlignCenter: { context.coordinator.applyAlignment(.center, to: textView) },
            onAlignRight: { context.coordinator.applyAlignment(.right, to: textView) }
        )
        
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.backgroundColor = .clear
        
        let size = hostingController.view.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: 100))
        hostingController.view.frame = CGRect(x: 0, y: 0, width: size.width, height: 50)
        
        textView.inputAccessoryView = hostingController.view
        context.coordinator.toolbarHostingController = hostingController
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let coordinator = context.coordinator
        let fontChanged = coordinator.currentFont?.fontName != font.fontName || coordinator.currentFont?.pointSize != font.pointSize
        let lineSpacingChanged = abs(coordinator.currentLineSpacing - lineSpacing) > 0.1
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = lineSpacing * 0.5
        
        let currentAlignment: NSTextAlignment
        let cursorLocation = uiView.selectedRange.location
        if cursorLocation < uiView.attributedText.length {
            if let style = uiView.attributedText.attribute(.paragraphStyle, at: cursorLocation, effectiveRange: nil) as? NSParagraphStyle {
                currentAlignment = style.alignment
            } else {
                currentAlignment = .left
            }
        } else if uiView.attributedText.length > 0 {
            if let style = uiView.attributedText.attribute(.paragraphStyle, at: uiView.attributedText.length - 1, effectiveRange: nil) as? NSParagraphStyle {
                currentAlignment = style.alignment
            } else {
                currentAlignment = .left
            }
        } else {
            currentAlignment = .left
        }
        paragraphStyle.alignment = currentAlignment
        
        coordinator.isUpdating = true
        coordinator.currentFont = font
        coordinator.currentLineSpacing = lineSpacing
        
        uiView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]
        
        if fontChanged || lineSpacingChanged {
            let attributedString = NSMutableAttributedString(attributedString: uiView.attributedText)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            
            if fullRange.length > 0 {
                attributedString.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                    let newParagraphStyle = NSMutableParagraphStyle()
                    if let existingStyle = value as? NSParagraphStyle {
                        newParagraphStyle.setParagraphStyle(existingStyle)
                    }
                    newParagraphStyle.lineSpacing = lineSpacing
                    newParagraphStyle.paragraphSpacing = lineSpacing * 0.5
                    attributedString.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
                }
                
                attributedString.addAttribute(.font, value: font, range: fullRange)
                attributedString.addAttribute(.foregroundColor, value: textColor, range: fullRange)
                
                let selectedRange = uiView.selectedRange
                uiView.attributedText = attributedString
                uiView.selectedRange = selectedRange
            }
        }
        
        if uiView.attributedText != attributedText && !attributedText.string.isEmpty {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }
        
        coordinator.isUpdating = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isUpdating = false
        var currentFont: UIFont?
        var currentLineSpacing: CGFloat = 4
        var toolbarHostingController: UIHostingController<RichTextFormatToolbar>?
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
            self.currentFont = parent.font
            self.currentLineSpacing = parent.lineSpacing
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if !isUpdating {
                parent.attributedText = textView.attributedText
                parent.onTextChange?()
            }
        }
        
        // MARK: - UIScrollViewDelegate
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            if let textView = scrollView as? UITextView, textView.isFirstResponder {
                textView.resignFirstResponder()
            }
        }
        
        // MARK: - Formatting Actions
        
        func applyBold(to textView: UITextView) {
            toggleAttribute(.traitBold, for: textView)
        }
        
        func applyItalic(to textView: UITextView) {
            toggleAttribute(.traitItalic, for: textView)
        }
        
        func applyUnderline(to textView: UITextView) {
            let range = textView.selectedRange
            if range.length > 0 {
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
                let currentUnderline = attributedText.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? NSNumber
                let newUnderline: NSNumber = (currentUnderline != nil) ? 0 : 1
                attributedText.addAttribute(.underlineStyle, value: newUnderline, range: range)
                textView.attributedText = attributedText
                textView.selectedRange = range
                parent.attributedText = attributedText
            }
        }
        
        func applyStrikethrough(to textView: UITextView) {
            let range = textView.selectedRange
            if range.length > 0 {
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
                let currentStrikethrough = attributedText.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? NSNumber
                let newStrikethrough: NSNumber = (currentStrikethrough != nil) ? 0 : 1
                attributedText.addAttribute(.strikethroughStyle, value: newStrikethrough, range: range)
                textView.attributedText = attributedText
                textView.selectedRange = range
                parent.attributedText = attributedText
            }
        }
        
        func applyAlignment(_ alignment: NSTextAlignment, to textView: UITextView) {
            let range = textView.selectedRange
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            paragraphStyle.lineSpacing = currentLineSpacing
            
            if range.length > 0 {
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                textView.attributedText = attributedText
                parent.attributedText = attributedText
            }
            
            textView.typingAttributes[.paragraphStyle] = paragraphStyle
            textView.selectedRange = range
        }
        
        private func toggleAttribute(_ trait: UIFontDescriptor.SymbolicTraits, for textView: UITextView) {
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentFont = attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? parent.font
            
            var newTraits = currentFont.fontDescriptor.symbolicTraits
            if newTraits.contains(trait) {
                newTraits.remove(trait)
            } else {
                newTraits.insert(trait)
            }
            
            if let newDescriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                attributedText.addAttribute(.font, value: newFont, range: range)
                textView.attributedText = attributedText
                textView.selectedRange = range
                parent.attributedText = attributedText
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
    let onAlignLeft: () -> Void
    let onAlignCenter: () -> Void
    let onAlignRight: () -> Void
    
    @StateObject private var fontManager = FontManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Font dropdown
            Menu {
                ForEach(AppFont.allCases) { font in
                    Button(action: {
                        fontManager.currentFont = font
                    }) {
                        HStack {
                            Text(font.displayName)
                                .font(font == .system ? .system(size: 14) : Font.custom(font.uiFont(size: 14).fontName, size: 14))
                            Spacer()
                            if fontManager.currentFont == font {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                    }
                }
            } label: {
                Text(fontManager.currentFont.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "0D244D"))
            }
            
            Divider()
                .frame(height: 24)
            
            // Size dropdown
            Menu {
                let sizes: [CGFloat] = [11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24]
                ForEach(sizes, id: \.self) { size in
                    Button(action: {
                        fontManager.writingFontSize = size
                    }) {
                        HStack {
                            Text("\(Int(size))pt")
                                .font(.system(size: 14))
                            Spacer()
                            if fontManager.writingFontSize == size {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                    }
                }
            } label: {
                Text("\(Int(fontManager.writingFontSize))pt")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "0D244D"))
            }
            
            Divider()
                .frame(height: 24)
            
            // Formatting buttons
            Button(action: onBold) {
                Text("B")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "0D244D"))
            }
            
            Button(action: onItalic) {
                Text("I")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(Color(hex: "0D244D"))
            }
            
            Button(action: onUnderline) {
                Text("U")
                    .font(.system(size: 18))
                    .underline()
                    .foregroundColor(Color(hex: "0D244D"))
            }
            
            Divider()
                .frame(height: 24)
            
            // Alignment buttons
            HStack(spacing: 12) {
                Button(action: onAlignLeft) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "0D244D"))
                }
                
                Button(action: onAlignCenter) {
                    Image(systemName: "text.aligncenter")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "0D244D"))
                }
                
                Button(action: onAlignRight) {
                    Image(systemName: "text.alignright")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "0D244D"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "f2f2f2"))
    }
}
