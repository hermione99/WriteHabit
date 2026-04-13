import SwiftUI
import UIKit

struct SimpleWritingEditorView: View {
    let keyword: String
    let existingEssay: Essay?  // nil = new essay, non-nil = edit mode
    let isDraft: Bool  // true = draft, false = published essay
    
    @State private var title = ""
    @State private var content = ""
    @State private var visibility: EssayVisibility = .friends
    @State private var showingPublishConfirmation = false
    @State private var isPublishing = false
    @StateObject private var fontManager = FontManager.shared
    @State private var showingFormatMenu = false
    @Environment(\.dismiss) private var dismiss
    
    init(keyword: String, existingEssay: Essay? = nil, isDraft: Bool = false) {
        self.keyword = keyword
        self.existingEssay = existingEssay
        self.isDraft = isDraft
        if let essay = existingEssay {
            _title = State(initialValue: essay.title)
            _content = State(initialValue: essay.content)
            _visibility = State(initialValue: essay.visibility)
        }
    }
    
    var wordCount: Int {
        return content.filter { !$0.isWhitespace }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Paper texture background
                PaperBackgroundView()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Big keyword display
                        VStack(alignment: .center, spacing: 8) {
                            if existingEssay == nil {
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
                        
                        // Word count
                        HStack {
                            Spacer()
                            Text("\(wordCount) \("words".localized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Title
                        TextField("Title (optional)".localized, text: $title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        // Content with grammar checking
                        GrammarTextEditor(
                            text: $content,
                            font: UIFont(name: fontManager.currentFont.rawValue, size: fontManager.writingFontSize) ?? UIFont.systemFont(ofSize: fontManager.writingFontSize),
                            textColor: UIColor.label
                        )
                        .frame(maxHeight: .infinity)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                    
                    // Bottom toolbar like Apple Notes
                    BottomFormatToolbar(
                        fontManager: fontManager,
                        onShowFormatMenu: { showingFormatMenu = true }
                    )
                    
                    .background(Color(.systemBackground))
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Write".localized)
            .navigationBarTitleDisplayMode(.inline)
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
                                        Text(option.displayName.localized)
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
                                Text(visibility.displayName.localized)
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                        
                        // Publish button
                        Button {
                            showingPublishConfirmation = true
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        // Save draft button
                        Button {
                            saveDraft()
                        } label: {
                            Image(systemName: "doc.text")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        // Format menu
                        Button {
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
                    onInsertHeading: insertHeading,
                    onInsertFormat: insertAroundSelection
                )
            }
            .alert("Publish Essay?".localized, isPresented: $showingPublishConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Publish".localized) {
                    publishEssay()
                }
            } message: {
                Text(String(format: "Your essay will be published as %@".localized, visibility.displayName.localized))
            }
        }
    }
    
    private func saveDraft() {
        Task {
            do {
                if let essay = existingEssay {
                    // Update existing draft
                    _ = try await FirebaseService.shared.updateDraft(
                        essayId: essay.id!,
                        title: title,
                        content: content
                    )
                } else {
                    // Create new draft
                    _ = try await FirebaseService.shared.saveDraft(
                        keyword: keyword,
                        title: title,
                        content: content
                    )
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving draft: \(error)")
            }
        }
    }
    
    private func publishEssay() {
        isPublishing = true
        
        Task {
            do {
                if let essay = existingEssay {
                    // Update existing essay
                    _ = try await FirebaseService.shared.updateEssay(
                        essayId: essay.id!,
                        title: title,
                        content: content
                    )
                    // Update visibility separately if changed
                    if essay.visibility != visibility {
                        try await FirebaseService.shared.updateEssayVisibility(
                            essayId: essay.id!,
                            visibility: visibility
                        )
                    }
                } else {
                    // Create new essay
                    _ = try await FirebaseService.shared.createEssay(
                        keyword: keyword,
                        title: title,
                        content: content,
                        visibility: visibility
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
                }
            }
        }
    }
    
    private func insertHeading(_ prefix: String) {
        if content.isEmpty {
            content = prefix
        } else if content.hasSuffix("\n") {
            content += prefix
        } else {
            content += "\n" + prefix
        }
    }
    
    private func insertAroundSelection(_ prefix: String, _ suffix: String) {
        content += prefix + suffix
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
    let onInsertHeading: (String) -> Void
    let onInsertFormat: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Headings".localized) {
                    Button {
                        onInsertHeading("# ")
                        dismiss()
                    } label: {
                        Text("Heading".localized)
                            .font(.title3.weight(.bold))
                    }
                    
                    Button {
                        onInsertHeading("## ")
                        dismiss()
                    } label: {
                        Text("Subheading".localized)
                            .font(.headline)
                    }
                    
                    Button {
                        onInsertHeading("### ")
                        dismiss()
                    } label: {
                        Text("Sub-subheading".localized)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                
                Section("Formatting".localized) {
                    HStack(spacing: 16) {
                        FormatButton(icon: "italic", action: { onInsertFormat("*", "*"); dismiss() })
                        FormatButton(icon: "bold", action: { onInsertFormat("**", "**"); dismiss() })
                        FormatButton(icon: "underline", action: { onInsertFormat("<u>", "</u>"); dismiss() })
                        FormatButton(icon: "strikethrough", action: { onInsertFormat("~~", "~~"); dismiss() })
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
    let onShowFormatMenu: () -> Void
    @State private var showingFontPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Font size controls (Aa)
                HStack(spacing: 8) {
                    Button {
                        let newSize = max(14, fontManager.writingFontSize - 2)
                        fontManager.setFontSize(newSize)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.system(size: 16))
                    }
                    .disabled(fontManager.writingFontSize <= 14)
                    
                    Text("\(Int(fontManager.writingFontSize))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 24)
                    
                    Button {
                        let newSize = min(32, fontManager.writingFontSize + 2)
                        fontManager.setFontSize(newSize)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.system(size: 16))
                    }
                    .disabled(fontManager.writingFontSize >= 32)
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
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                }
                .sheet(isPresented: $showingFontPicker) {
                    SimpleFontPickerSheet(fontManager: fontManager)
                }
                
                Spacer()
                
                // Spell check button
                Button {
                    // Toggle spell checking - this triggers the native spell check UI
                    NotificationCenter.default.post(name: .init("ToggleSpellCheck"), object: nil)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18))
                }
                
                // Format menu button
                Button {
                    onShowFormatMenu()
                } label: {
                    Image(systemName: "textformat.alt")
                        .font(.system(size: 20))
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
                                    .foregroundStyle(.blue)
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
