import SwiftUI
import UIKit

// Custom TextView with spell checking and grammar support
struct GrammarTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var textColor: UIColor
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        
        // Enable spell checking and grammar
        textView.spellCheckingType = .yes
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        
        // Smart quotes and dashes
        textView.smartQuotesType = .yes
        textView.smartDashesType = .yes
        textView.smartInsertDeleteType = .yes
        
        // Data detection (links, phone numbers, etc.)
        textView.dataDetectorTypes = .all
        
        // Other settings
        textView.isScrollEnabled = true
        textView.isSelectable = true
        textView.isEditable = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrammarTextEditor
        
        init(_ parent: GrammarTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

// Spell check helper view
struct SpellCheckView: View {
    @Binding var text: String
    @State private var showingCheckSheet = false
    @State private var suggestions: [SpellCheckSuggestion] = []
    
    var body: some View {
        Button {
            checkSpelling()
        } label: {
            Label("Check Spelling".localized, systemImage: "textformat.abc")
        }
        .sheet(isPresented: $showingCheckSheet) {
            SpellCheckSheet(text: $text, suggestions: suggestions)
        }
    }
    
    private func checkSpelling() {
        // Use native UITextChecker
        let textChecker = UITextChecker()
        let nsString = text as NSString
        var foundIssues: [SpellCheckSuggestion] = []
        
        var offset = 0
        while offset < nsString.length {
            let range = NSRange(location: offset, length: nsString.length - offset)
            
            // Find misspelled word
            let misspelledRange = textChecker.rangeOfMisspelledWord(
                in: text,
                range: range,
                startingAt: 0,
                wrap: false,
                language: Locale.preferredLanguages.first ?? "en"
            )
            
            if misspelledRange.location == NSNotFound {
                break
            }
            
            let word = nsString.substring(with: misspelledRange)
            let guesses = textChecker.guesses(forWordRange: misspelledRange, in: text, language: Locale.preferredLanguages.first ?? "en") ?? []
            
            foundIssues.append(SpellCheckSuggestion(
                word: word,
                range: misspelledRange,
                suggestions: guesses
            ))
            
            offset = misspelledRange.location + misspelledRange.length
        }
        
        suggestions = foundIssues
        showingCheckSheet = !foundIssues.isEmpty
    }
}

struct SpellCheckSuggestion: Identifiable {
    let id = UUID()
    let word: String
    let range: NSRange
    let suggestions: [String]
}

// Sheet to show and fix spelling issues
struct SpellCheckSheet: View {
    @Binding var text: String
    let suggestions: [SpellCheckSuggestion]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if suggestions.isEmpty {
                    Section {
                        Label("No spelling issues found!".localized, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Section("Found \(suggestions.count) issues".localized) {
                        ForEach(suggestions) { issue in
                            SpellCheckRow(text: $text, suggestion: issue)
                        }
                    }
                }
            }
            .navigationTitle("Spelling Check".localized)
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

struct SpellCheckRow: View {
    @Binding var text: String
    let suggestion: SpellCheckSuggestion
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.word)
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            
            if isExpanded {
                if suggestion.suggestions.isEmpty {
                    Text("No suggestions".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(suggestion.suggestions, id: \.self) { guess in
                            Button {
                                applyCorrection(guess)
                            } label: {
                                Text(guess)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func applyCorrection(_ correction: String) {
        let nsString = text as NSString
        let newText = nsString.replacingCharacters(in: suggestion.range, with: correction)
        text = newText
    }
}

// Simple flow layout for suggestions
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// Preview
#Preview {
    GrammarTextEditor(
        text: .constant("This is a test."),
        font: UIFont.systemFont(ofSize: 17),
        textColor: .label
    )
    .frame(height: 200)
}
