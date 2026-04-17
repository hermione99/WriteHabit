import SwiftUI
import UIKit
import FirebaseAuth

struct SimpleWritingEditorView: View {
    let keyword: String
    let existingEssay: Essay?  // nil = new essay, non-nil = edit mode
    let isDraft: Bool  // true = draft, false = published essay
    let isPastTopic: Bool  // true = writing on past keyword (no streak impact)
    
    @State private var title = ""
    @State private var content = ""  // Plain text for word count and storage
    @State private var attributedContent = NSAttributedString(string: "")  // Rich text
    @State private var visibility: EssayVisibility = .friends
    @State private var showingPublishConfirmation = false
    @State private var isPublishing = false
    @State private var hasPublished = false  // Track if already published
    @StateObject private var fontManager = FontManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingFormatMenu = false
    @State private var showingSaveDraftConfirmation = false
    @State private var showingExistingEssayAlert = false
    @State private var existingEssayForKeyword: Essay? = nil
    @State private var textView: UITextView?  // Reference to the underlying text view
    @State private var savedCursorLocation: Int = 0  // Save cursor position before sheet opens
    @State private var saveDraftTimer: Timer? = nil  // Debounce timer for auto-save
    @Environment(\.dismiss) private var dismiss
    
    init(keyword: String, existingEssay: Essay? = nil, isDraft: Bool = false, isPastTopic: Bool = false) {
        self.keyword = keyword
        self.existingEssay = existingEssay
        self.isDraft = isDraft
        self.isPastTopic = isPastTopic
        if let essay = existingEssay {
            _title = State(initialValue: essay.title)
            _content = State(initialValue: essay.content)
            // Load attributed content if available
            if let attributedStringBase64 = essay.attributedContentData,
               let attributedData = Data(base64Encoded: attributedStringBase64),
               let nsAttributedString = try? NSAttributedString(data: attributedData, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil) {
                _attributedContent = State(initialValue: nsAttributedString)
            } else {
                // Create attributed string from plain content
                _attributedContent = State(initialValue: NSAttributedString(string: essay.content))
            }
            _visibility = State(initialValue: essay.visibility)
            
            // Restore saved font settings to FontManager when opening existing essay
            // Use async to avoid publishing during init
            if let fontName = essay.fontName,
               let savedFont = AppFont(rawValue: fontName) {
                DispatchQueue.main.async {
                    FontManager.shared.setFont(savedFont)
                }
            }
            if let fontSize = essay.fontSize {
                DispatchQueue.main.async {
                    FontManager.shared.setFontSize(fontSize)
                }
            }
            if let lineSpacing = essay.lineSpacing {
                DispatchQueue.main.async {
                    FontManager.shared.setLineSpacing(lineSpacing)
                }
            }
        }
    }
    
    var wordCount: Int {
        return content.filter { !$0.isWhitespace }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Hidden text field to warm up keyboard (prevents lag on first tap)
                TextField("", text: .constant(""))
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .keyboardType(.default)
                    .onAppear {
                        // Trigger keyboard warmup
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                
                // Paper texture background
                PaperBackgroundView()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Big keyword display
                        VStack(alignment: .center, spacing: 8) {
                            if isPastTopic {
                                Text("Past Topic".localized)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .textCase(.uppercase)
                            } else if existingEssay == nil {
                                Text("Today's Prompt".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                            } else {
                                Text(isDraft ? "Edit Draft".localized : "Edit Essay".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                            }
                            
                            Text(keyword)
                                .font(.system(.largeTitle, design: .serif))
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 20)
                        
                        // Title field - always system font
                        TextField("Title".localized, text: $title)
                            .font(.system(size: fontManager.writingFontSize + 6, weight: .semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Word count
                        HStack {
                            Spacer()
                            Text("\(wordCount) \("words".localized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Content with rich text editing
                        RichTextEditor(
                            attributedText: $attributedContent,
                            font: self.fontManager.currentFont.uiFont(size: self.fontManager.writingFontSize),
                            textColor: UIColor.label,
                            lineSpacing: self.fontManager.lineSpacing,
                            onTextViewCreated: { textView in
                                self.textView = textView
                            },
                            onTextChange: {
                                // Real-time word count update
                                self.content = self.attributedContent.string
                            }
                        )
                        .frame(maxHeight: .infinity)
                        // Update font at cursor/selection when font changes
                        .onChange(of: fontManager.currentFont) { _, _ in
                            guard let textView = textView else { return }
                            let newFont = fontManager.currentFont.uiFont(size: fontManager.writingFontSize)
                            let selectedRange = textView.selectedRange
                            
                            // Apply to selected text, or current paragraph if no selection
                            let rangeToApply: NSRange
                            if selectedRange.length > 0 {
                                rangeToApply = selectedRange
                            } else {
                                // Find current paragraph
                                let text = textView.textStorage.string
                                let currentLocation = selectedRange.location
                                var paraStart = currentLocation
                                var paraEnd = currentLocation
                                
                                // Find paragraph boundaries
                                while paraStart > 0 {
                                    let idx = text.index(text.startIndex, offsetBy: paraStart - 1)
                                    if text[idx] == "\n" { break }
                                    paraStart -= 1
                                }
                                while paraEnd < text.count {
                                    let idx = text.index(text.startIndex, offsetBy: paraEnd)
                                    if text[idx] == "\n" { break }
                                    paraEnd += 1
                                }
                                rangeToApply = NSMakeRange(paraStart, paraEnd - paraStart)
                            }
                            
                            if rangeToApply.length > 0 {
                                textView.textStorage.addAttribute(.font, value: newFont, range: rangeToApply)
                                attributedContent = textView.attributedText
                            }
                            
                            // Update typing attributes for new text
                            textView.typingAttributes[.font] = newFont
                        }
                        .onChange(of: fontManager.writingFontSize) { _, _ in
                            guard let textView = textView else { return }
                            let newFont = fontManager.currentFont.uiFont(size: fontManager.writingFontSize)
                            let selectedRange = textView.selectedRange
                            
                            // Apply to selected text, or current paragraph if no selection
                            let rangeToApply: NSRange
                            if selectedRange.length > 0 {
                                rangeToApply = selectedRange
                            } else {
                                // Find current paragraph
                                let text = textView.textStorage.string
                                let currentLocation = selectedRange.location
                                var paraStart = currentLocation
                                var paraEnd = currentLocation
                                
                                while paraStart > 0 {
                                    let idx = text.index(text.startIndex, offsetBy: paraStart - 1)
                                    if text[idx] == "\n" { break }
                                    paraStart -= 1
                                }
                                while paraEnd < text.count {
                                    let idx = text.index(text.startIndex, offsetBy: paraEnd)
                                    if text[idx] == "\n" { break }
                                    paraEnd += 1
                                }
                                rangeToApply = NSMakeRange(paraStart, paraEnd - paraStart)
                            }
                            
                            if rangeToApply.length > 0 {
                                textView.textStorage.addAttribute(.font, value: newFont, range: rangeToApply)
                                attributedContent = textView.attributedText
                            }
                            
                            textView.typingAttributes[.font] = newFont
                        }
                        .onChange(of: fontManager.lineSpacing) { _, _ in
                            guard let textView = textView else { return }
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.lineSpacing = fontManager.lineSpacing
                            
                            let selectedRange = textView.selectedRange
                            let rangeToApply: NSRange
                            if selectedRange.length > 0 {
                                rangeToApply = selectedRange
                            } else {
                                // Find current paragraph
                                let text = textView.textStorage.string
                                let currentLocation = selectedRange.location
                                var paraStart = currentLocation
                                var paraEnd = currentLocation
                                
                                while paraStart > 0 {
                                    let idx = text.index(text.startIndex, offsetBy: paraStart - 1)
                                    if text[idx] == "\n" { break }
                                    paraStart -= 1
                                }
                                while paraEnd < text.count {
                                    let idx = text.index(text.startIndex, offsetBy: paraEnd)
                                    if text[idx] == "\n" { break }
                                    paraEnd += 1
                                }
                                rangeToApply = NSMakeRange(paraStart, paraEnd - paraStart)
                            }
                            
                            if rangeToApply.length > 0 {
                                textView.textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: rangeToApply)
                                attributedContent = textView.attributedText
                            }
                            
                            textView.typingAttributes[.paragraphStyle] = paragraphStyle
                        }
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                    // Swipe down to dismiss keyboard
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    // Swipe down more than 100 points dismisses keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                    )
                    // Tap anywhere on the text editor to dismiss keyboard
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    )
                    
                    // Bottom toolbar with rich text formatting
                    RichTextFormatToolbar(
                        onBold: { applyFormatting(.bold) },
                        onItalic: { applyFormatting(.italic) },
                        onUnderline: { applyFormatting(.underline) },
                        onStrikethrough: { applyFormatting(.strikethrough) }
                    )
                    .background(Color(.systemBackground))
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("")
            .onAppear {
                #if DEBUG
                print("[DEBUG] SimpleWritingEditorView appeared")
                #endif
                // Restore saved font and line spacing when editing existing essay
                if let essay = existingEssay {
                    if let fontName = essay.fontName,
                       let savedFont = AppFont(rawValue: fontName) {
                        fontManager.currentFont = savedFont
                    }
                    if let savedLineSpacing = essay.lineSpacing {
                        fontManager.lineSpacing = savedLineSpacing
                    }
                    if let savedFontSize = essay.fontSize {
                        fontManager.writingFontSize = CGFloat(savedFontSize)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Visibility dropdown
                        Menu {
                            ForEach(EssayVisibility.allCases, id: \.self) { option in
                                Button {
                                    visibility = option
                                } label: {
                                    HStack {
                                        Image(systemName: option.icon)
                                        Text(option.displayName)
                                        Spacer()
                                        if visibility == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: visibility.icon)
                                Text(visibility.displayName)
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundStyle(themeManager.accent)
                        }
                        
                        // Save draft button
                        Button {
                            showingSaveDraftConfirmation = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        // Publish button
                        Button {
                            guard !isPublishing && !hasPublished else { return }
                            showingPublishConfirmation = true
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .disabled(isPublishing || hasPublished)
                        
                        // Format menu
                        Button {
                            savedCursorLocation = textView?.selectedRange.location ?? 0
                            showingFormatMenu = true
                        } label: {
                            Image(systemName: "textformat")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFormatMenu) {
                FormatMenuSheet(
                    fontManager: fontManager,
                    onInsertFormat: insertAroundSelection,
                    onApplyAlignment: applyAlignment
                )
            }
            .alert("Publish Essay?".localized, isPresented: $showingPublishConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Publish".localized) {
                    publishEssay()
                }
            } message: {
                Text(String(format: "Your essay will be published as %@".localized, visibility.displayName))
            }
            .alert("Save as Draft?".localized, isPresented: $showingSaveDraftConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Save".localized) {
                    saveDraft()
                }
            } message: {
                Text("Save this essay as a draft? You can continue editing later.".localized)
            }
            .alert("Already Written".localized, isPresented: $showingExistingEssayAlert) {
                Button("Edit Existing".localized) {
                    // Navigate to existing essay
                    if let essay = existingEssayForKeyword {
                        // Dismiss and open existing essay
                        dismiss()
                        // TODO: Navigate to essay detail for editing
                    }
                }
                Button("Cancel".localized, role: .cancel) { }
            } message: {
                Text("You already wrote about this topic. Would you like to edit your existing essay?".localized)
            }
            .onChange(of: showingPublishConfirmation) { newValue in
                #if DEBUG
                print("[DEBUG] showingPublishConfirmation changed to: \(newValue)")
                #endif
            }
            .onDisappear {
                // Cancel any pending auto-save timer
                saveDraftTimer?.invalidate()
                saveDraftTimer = nil
            }
        }
    }
    
    private func saveDraft() {
        // Prevent multiple calls
        guard !isPublishing else { return }
        
        isPublishing = true
        Task {
            do {
                // Capture font settings
                let currentFontName = fontManager.currentFont.rawValue
                let currentLineSpacing = Double(fontManager.lineSpacing)
                let currentFontSize = Double(fontManager.writingFontSize)
                
                // Convert attributed content to data and then to base64 string
                let attributedData = try? attributedContent.data(from: NSRange(location: 0, length: attributedContent.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
                let attributedContentBase64 = attributedData?.base64EncodedString()
                
                // Get plain text for word count
                content = attributedContent.string
                
                // Always create a new draft - don't update existing
                #if DEBUG
                print("[DEBUG] Creating NEW draft with keyword: \(keyword)")
                #endif
                let savedDraft = try await FirebaseService.shared.saveDraft(
                    keyword: keyword,
                    title: title,
                    content: content,
                    fontName: currentFontName,
                    lineSpacing: currentLineSpacing,
                    fontSize: currentFontSize,
                    attributedContentData: attributedContentBase64
                )
                #if DEBUG
                print("[DEBUG] Created draft with ID: \(savedDraft.id ?? "nil")")
                #endif
                
                await MainActor.run {
                    isPublishing = false
                    dismiss()
                }
            } catch {
                print("Error saving draft: \(error)")
                await MainActor.run {
                    isPublishing = false
                }
            }
        }
    }
    
    private func debouncedSaveDraft() {
        // Cancel existing timer
        saveDraftTimer?.invalidate()
        
        // Set new timer - save after 2 seconds of no typing
        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task {
                await MainActor.run {
                    self.saveDraft()
                }
            }
        }
    }
    
    private func publishEssay() {
        // Prevent multiple calls
        guard !isPublishing && !hasPublished else {
            #if DEBUG
            print("[DEBUG] publishEssay blocked - isPublishing: \(isPublishing), hasPublished: \(hasPublished)")
            #endif
            return
        }
        
        // Check if user already has a published essay for this keyword
        if existingEssay == nil, let userId = Auth.auth().currentUser?.uid {
            Task {
                do {
                    if let existingPublishedEssay = try await FirebaseService.shared.getPublishedEssayForKeyword(userId: userId, keyword: keyword) {
                        // User already has a published essay for this keyword
                        await MainActor.run {
                            isPublishing = false
                            hasPublished = false
                            showingExistingEssayAlert = true
                            existingEssayForKeyword = existingPublishedEssay
                        }
                    } else {
                        // No existing essay, proceed with publish
                        await MainActor.run {
                            proceedWithPublish()
                        }
                    }
                } catch {
                    await MainActor.run {
                        isPublishing = false
                        hasPublished = false
                    }
                }
            }
            return
        }
        
        proceedWithPublish()
    }
    
    private func proceedWithPublish() {
        let callId = UUID().uuidString.prefix(8)
        #if DEBUG
        print("[DEBUG publishEssay #\(callId)] Starting publish")
        #endif
        
        hasPublished = true
        isPublishing = true
        
        // Capture font settings before entering async context
        let currentFontName = fontManager.currentFont.rawValue
        let currentLineSpacing = Double(fontManager.lineSpacing)
        let currentFontSize = Double(fontManager.writingFontSize)
        
        // Get plain text from attributed string for word count
        content = attributedContent.string
        
        // Convert attributed content to data and then to base64 string
        let attributedData = try? attributedContent.data(from: NSRange(location: 0, length: attributedContent.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
        let attributedContentBase64 = attributedData?.base64EncodedString()
        
        Task {
            do {
                if let essay = existingEssay {
                    #if DEBUG
                    print("[DEBUG #\(callId)] Updating existing essay: \(essay.id ?? "nil"), isDraft: \(isDraft)")
                    #endif
                    // Update existing essay with font and line spacing and attributed content
                    _ = try await FirebaseService.shared.updateEssay(
                        essayId: essay.id!,
                        title: title,
                        content: content,
                        fontName: currentFontName,
                        lineSpacing: currentLineSpacing,
                        fontSize: currentFontSize,
                        attributedContentData: attributedContentBase64
                    )
                    // Update visibility separately if changed
                    if essay.visibility != visibility {
                        try await FirebaseService.shared.updateEssayVisibility(
                            essayId: essay.id!,
                            visibility: visibility
                        )
                    }
                    // If it was a draft, mark as published (not draft)
                    if isDraft {
                        try await FirebaseService.shared.publishDraft(essayId: essay.id!, visibility: visibility)
                    }
                } else {
                    #if DEBUG
                    print("[DEBUG #\(callId)] Creating NEW essay (existingEssay is nil)")
                    #endif
                    // Create new essay with font, line spacing, and attributed content
                    _ = try await FirebaseService.shared.createEssay(
                        keyword: keyword,
                        title: title,
                        content: content,
                        visibility: visibility,
                        fontName: currentFontName,
                        lineSpacing: currentLineSpacing,
                        fontSize: currentFontSize,
                        attributedContentData: attributedContentBase64
                    )
                }
                await MainActor.run {
                    isPublishing = false
                    dismiss()
                }
            } catch {
                print("Error publishing: \(error)")
                await MainActor.run {
                    isPublishing = false
                    hasPublished = false  // Reset on error so user can retry
                }
            }
        }
    }
    private func insertAroundSelection(_ prefix: String, _ suffix: String) {
        // For regular formatting like **bold**, just insert plain text
        // The user will type between the markers
        guard let textView = textView else { return }
        
        let mutableAttrText = NSMutableAttributedString(attributedString: attributedContent)
        let insertString = prefix + suffix
        let attrString = NSAttributedString(string: insertString, attributes: [
            .font: fontManager.currentFont.uiFont(size: fontManager.writingFontSize),
            .foregroundColor: UIColor.label
        ])
        
        mutableAttrText.insert(attrString, at: textView.selectedRange.location)
        attributedContent = mutableAttrText
    }
    
    private func insertDivider(_ dividerText: String) {
        print("Inserting divider: \(dividerText)")
        
        let mutableAttrText = NSMutableAttributedString(attributedString: attributedContent)
        
        // Insert location
        let insertLocation = min(savedCursorLocation, mutableAttrText.length)
        
        // Create paragraph style with full-width line
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.paragraphSpacingBefore = 8
        
        // Create a full-width visual divider
        // Use simple characters that don't have built-in underlines
        var dividerString: String
        var dividerAttrs: [NSAttributedString.Key: Any]
        
        switch dividerText {
        case "---":
            // Simple solid line using bullet points
            let bullets = Array(repeating: "•", count: 50).joined()
            dividerString = "\n" + bullets + "\n"
            dividerAttrs = [
                .font: UIFont.systemFont(ofSize: 6),
                .foregroundColor: UIColor.gray,
                .paragraphStyle: paragraphStyle
            ]
        case "- - -":
            // Dashed line with spaced bullets
            let bullets = Array(repeating: "•", count: 30).joined(separator: "   ")
            dividerString = "\n" + bullets + "\n"
            dividerAttrs = [
                .font: UIFont.systemFont(ofSize: 6),
                .foregroundColor: UIColor.gray.withAlphaComponent(0.7),
                .paragraphStyle: paragraphStyle
            ]
        case "===":
            // Double line using two rows of bullets
            let bullets = Array(repeating: "•", count: 50).joined()
            dividerString = "\n" + bullets + "\n" + bullets + "\n"
            dividerAttrs = [
                .font: UIFont.systemFont(ofSize: 6),
                .foregroundColor: UIColor.gray,
                .paragraphStyle: paragraphStyle
            ]
        default:
            dividerString = "\n" + dividerText + "\n"
            dividerAttrs = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray,
                .paragraphStyle: paragraphStyle
            ]
        }
        
        let dividerAttrString = NSAttributedString(string: dividerString, attributes: dividerAttrs)
        
        // Insert the divider
        mutableAttrText.insert(dividerAttrString, at: insertLocation)
        
        // Insert a zero-width space with normal font to reset typing attributes
        let resetAttrString = NSAttributedString(string: "\u{200B}", attributes: [
            .font: fontManager.currentFont.uiFont(size: fontManager.writingFontSize),
            .foregroundColor: UIColor.label
        ])
        let afterDividerLocation = insertLocation + dividerString.count
        mutableAttrText.insert(resetAttrString, at: afterDividerLocation)
        
        attributedContent = mutableAttrText
        
        // Update saved location for next insertion
        savedCursorLocation = afterDividerLocation + 1
        
        print("Full-width divider inserted at location: \(insertLocation)")
    }
    // MARK: - Rich Text Formatting
    
    enum TextFormatting {
        case bold
        case italic
        case underline
        case strikethrough
    }
    
    private func applyFormatting(_ formatting: TextFormatting) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0 else { return } // Need selection
        
        switch formatting {
        case .bold:
            toggleFontTrait(.traitBold, for: textView, range: selectedRange)
        case .italic:
            toggleFontTrait(.traitItalic, for: textView, range: selectedRange)
        case .underline:
            toggleUnderline(for: textView, range: selectedRange)
        case .strikethrough:
            toggleStrikethrough(for: textView, range: selectedRange)
        }
        
        // Update the attributed text binding
        attributedContent = textView.attributedText
    }
    
    private func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, for textView: UITextView, range: NSRange) {
        // Get the current font at the start of selection
        let currentAttributes = textView.textStorage.attributes(at: range.location, effectiveRange: nil)
        guard let currentFont = currentAttributes[.font] as? UIFont else { return }
        
        let descriptor = currentFont.fontDescriptor
        let hasTrait = descriptor.symbolicTraits.contains(trait)
        
        var newTraits = descriptor.symbolicTraits
        if hasTrait {
            newTraits.remove(trait)
        } else {
            newTraits.insert(trait)
        }
        
        guard let newDescriptor = descriptor.withSymbolicTraits(newTraits) else { return }
        let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
        
        textView.textStorage.addAttribute(.font, value: newFont, range: range)
        // Ensure text uses adaptive color after formatting
        textView.textStorage.addAttribute(.foregroundColor, value: UIColor.label, range: range)
    }
    
    private func toggleUnderline(for textView: UITextView, range: NSRange) {
        let currentAttributes = textView.textStorage.attributes(at: range.location, effectiveRange: nil)
        let currentUnderline = currentAttributes[.underlineStyle] as? Int ?? 0
        
        if currentUnderline == NSUnderlineStyle.single.rawValue {
            textView.textStorage.removeAttribute(.underlineStyle, range: range)
        } else {
            textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }
    
    private func toggleStrikethrough(for textView: UITextView, range: NSRange) {
        let currentAttributes = textView.textStorage.attributes(at: range.location, effectiveRange: nil)
        let hasStrikethrough = currentAttributes[.strikethroughStyle] != nil
        
        if hasStrikethrough {
            textView.textStorage.removeAttribute(.strikethroughStyle, range: range)
        } else {
            textView.textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }
    
    private func applyAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let rangeToAlign: NSRange
        
        // If no text is selected, align the current paragraph
        if selectedRange.length == 0 {
            // Find the current paragraph range
            let currentLocation = selectedRange.location
            let text = textView.textStorage.string
            
            // Find paragraph start
            var paragraphStart = currentLocation
            while paragraphStart > 0 {
                let prevIndex = text.index(text.startIndex, offsetBy: paragraphStart - 1)
                if text[prevIndex] == "\n" {
                    break
                }
                paragraphStart -= 1
            }
            
            // Find paragraph end
            var paragraphEnd = currentLocation
            while paragraphEnd < text.count {
                let currentIndex = text.index(text.startIndex, offsetBy: paragraphEnd)
                if text[currentIndex] == "\n" {
                    break
                }
                paragraphEnd += 1
            }
            
            rangeToAlign = NSMakeRange(paragraphStart, paragraphEnd - paragraphStart)
        } else {
            // Align the selected range
            rangeToAlign = selectedRange
        }
        
        // Apply paragraph style with alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = fontManager.lineSpacing
        paragraphStyle.paragraphSpacing = fontManager.lineSpacing * 0.5
        
        textView.textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: rangeToAlign)
        
        // Ensure text color remains adaptive
        textView.textStorage.addAttribute(.foregroundColor, value: UIColor.label, range: rangeToAlign)
        
        // Restore selected range
        textView.selectedRange = selectedRange
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func updateTextViewFont() {
        guard let textView = textView else { return }
        
        let newFont = fontManager.currentFont.uiFont(size: fontManager.writingFontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = fontManager.lineSpacing
        paragraphStyle.paragraphSpacing = fontManager.lineSpacing * 0.5
        
        // Update typing attributes for new text
        textView.typingAttributes = [
            .font: newFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
        
        // Update existing text
        let mutableAttrText = NSMutableAttributedString(attributedString: textView.attributedText)
        let fullRange = NSRange(location: 0, length: mutableAttrText.length)
        
        if fullRange.length > 0 {
            mutableAttrText.addAttribute(.font, value: newFont, range: fullRange)
            mutableAttrText.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
            mutableAttrText.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
            
            let selectedRange = textView.selectedRange
            textView.attributedText = mutableAttrText
            textView.selectedRange = selectedRange
            
            attributedContent = mutableAttrText
        }
    }
}

// MARK: - Paper Background (Adaptive)

struct PaperBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base color - adaptive
            ThemeColors.paperBackground(for: colorScheme)
                .ignoresSafeArea()
            
            // Subtle texture using overlay
            GeometryReader { geometry in
                Canvas { context, size in
                    // Draw subtle lines for paper texture
                    let lineSpacing: CGFloat = 4
                    var y: CGFloat = 0
                    
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        
                        context.stroke(
                            path,
                            with: .color(ThemeColors.paperLines(for: colorScheme)),
                            lineWidth: 0.5
                        )
                        
                        y += lineSpacing
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Format Menu Sheet

struct FormatMenuSheet: View {
    @ObservedObject var fontManager: FontManager
    let onInsertFormat: (String, String) -> Void
    let onApplyAlignment: (NSTextAlignment) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Formatting".localized) {
                    HStack(spacing: 16) {
                        FormatButton(icon: "italic", action: { onInsertFormat("*", "*"); dismiss() })
                        FormatButton(icon: "bold", action: { onInsertFormat("**", "**"); dismiss() })
                        FormatButton(icon: "underline", action: { onInsertFormat("<u>", "</u>"); dismiss() })
                        FormatButton(icon: "strikethrough", action: { onInsertFormat("~~", "~~"); dismiss() })
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Alignment".localized) {
                    HStack(spacing: 20) {
                        // Left align
                        Button {
                            onApplyAlignment(.left)
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 24))
                                Text("Left".localized)
                                    .font(.caption)
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        
                        // Center align
                        Button {
                            onApplyAlignment(.center)
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "text.aligncenter")
                                    .font(.system(size: 24))
                                Text("Center".localized)
                                    .font(.caption)
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        
                        // Right align
                        Button {
                            onApplyAlignment(.right)
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "text.alignright")
                                    .font(.system(size: 24))
                                Text("Right".localized)
                                    .font(.caption)
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Font".localized) {
                    Picker("Font".localized, selection: Binding(
                        get: { fontManager.currentFont },
                        set: { fontManager.setFont($0) }
                    )) {
                        ForEach(AppFont.allCases) { font in
                            Text(font.displayName)
                                .font(font.font(size: 16))
                                .tag(font)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    
                    HStack {
                        Text("Size".localized)
                        Spacer()
                        Text("\(Int(fontManager.writingFontSize))pt")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { fontManager.writingFontSize },
                        set: { fontManager.setFontSize($0) }
                    ), in: 14...32, step: 1)
                    
                    HStack {
                        Text("Line Spacing".localized)
                        Spacer()
                        Text(String(format: "%dpt", Int(fontManager.lineSpacing)))
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { fontManager.lineSpacing },
                        set: { fontManager.setLineSpacing($0) }
                    ), in: 0...20, step: 1)
                }
            }
            .navigationTitle("Format".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    SimpleWritingEditorView(keyword: "Serendipity")
}

// MARK: - Bottom Format Toolbar (Apple Notes style)

struct BottomFormatToolbar: View {
    @ObservedObject var fontManager: FontManager
    @StateObject private var themeManager = ThemeManager.shared
    let onShowFormatMenu: () -> Void
    let onInsertBold: () -> Void
    let onInsertItalic: () -> Void
    let onInsertUnderline: () -> Void
    let onInsertStrikethrough: () -> Void
    @State private var showingFontPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Format buttons (Bold, Italic, Underline, Strikethrough)
                HStack(spacing: 12) {
                    Button {
                        onInsertBold()
                    } label: {
                        Image(systemName: "bold")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager.accent)
                    }
                    
                    Button {
                        onInsertItalic()
                    } label: {
                        Image(systemName: "italic")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager.accent)
                    }
                    
                    Button {
                        onInsertUnderline()
                    } label: {
                        Image(systemName: "underline")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager.accent)
                    }
                    
                    Button {
                        onInsertStrikethrough()
                    } label: {
                        Image(systemName: "strikethrough")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager.accent)
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                // Font size controls (Aa)
                HStack(spacing: 8) {
                    Button {
                        let newSize = max(14, fontManager.writingFontSize - 2)
                        fontManager.setFontSize(newSize)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.system(size: 16))
                            .foregroundStyle(themeManager.accent)
                    }
                    .disabled(fontManager.writingFontSize <= 14)
                    
                    Text("\(Int(fontManager.writingFontSize))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 24)
                        .foregroundStyle(themeManager.accent)
                    
                    Button {
                        let newSize = min(32, fontManager.writingFontSize + 2)
                        fontManager.setFontSize(newSize)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.system(size: 16))
                            .foregroundStyle(themeManager.accent)
                    }
                    .disabled(fontManager.writingFontSize >= 32)
                }
                
                Divider()
                    .frame(height: 24)
                
                // Line spacing controls
                HStack(spacing: 8) {
                    Button {
                        let newSpacing = max(0, fontManager.lineSpacing - 2)
                        fontManager.setLineSpacing(newSpacing)
                    } label: {
                        Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager.accent)
                    }
                    .disabled(fontManager.lineSpacing <= 0)
                    
                    Text("\(Int(fontManager.lineSpacing))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 24)
                        .foregroundStyle(themeManager.accent)
                    
                    Button {
                        let newSpacing = min(20, fontManager.lineSpacing + 2)
                        fontManager.setLineSpacing(newSpacing)
                    } label: {
                        Image(systemName: "text.line.last.and.arrowtriangle.forward")
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager.accent)
                    }
                    .disabled(fontManager.lineSpacing >= 20)
                }
                
                Divider()
                    .frame(height: 24)
                
                // Font family picker
                Button {
                    showingFontPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(fontManager.currentFont.displayName)
                            .font(.subheadline)
                            .foregroundStyle(themeManager.accent)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(themeManager.accent)
                    }
                }
                .sheet(isPresented: $showingFontPicker) {
                    SimpleFontPickerSheet(fontManager: fontManager)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Simple Font Picker Sheet

struct SimpleFontPickerSheet: View {
    @ObservedObject var fontManager: FontManager
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppFont.allCases) { font in
                    Button {
                        fontManager.setFont(font)
                        dismiss()
                    } label: {
                        HStack {
                            Text(font.displayName)
                                .font(font.font(size: 17))
                            
                            Spacer()
                            
                            if fontManager.currentFont == font {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Font".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}
