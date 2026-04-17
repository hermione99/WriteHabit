import SwiftUI
import PDFKit
import FirebaseAuth

struct BookExportView: View {
    @State private var essays: [Essay] = []
    @State private var selectedEssays: Set<String> = []
    @State private var isLoading = true
    @State private var showPDFPreview = false
    @State private var pdfData: Data?
    @State private var bookTitle = "My Writing Collection"
    @State private var showingShareSheet = false
    @StateObject private var themeManager = ThemeManager.shared
    @State private var exportFormat: ExportFormat = .pdf
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case epub = "EPUB"
    }
    
    var selectedCount: Int {
        selectedEssays.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Book cover preview section
                Section {
                    VStack(spacing: 16) {
                        BookCoverPreview(
                            title: bookTitle,
                            essayCount: selectedCount,
                            date: Date()
                        )
                        .frame(height: 200)
                        
                        TextField("Book Title".localized, text: $bookTitle)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }
                
                // Format selection
                Section("Export Format".localized) {
                    Picker("Format".localized, selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Essay selection
                Section {
                    HStack {
                        Text("Select Essays".localized)
                            .font(.headline)
                        Spacer()
                        Button(selectedCount == essays.count ? "Deselect All".localized : "Select All".localized) {
                            if selectedCount == essays.count {
                                selectedEssays.removeAll()
                            } else {
                                selectedEssays = Set(essays.map { $0.id ?? "" })
                            }
                        }
                        .font(.caption)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if essays.isEmpty {
                        Text("No essays yet".localized)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(essays) { essay in
                            EssaySelectionRow(
                                essay: essay,
                                isSelected: selectedEssays.contains(essay.id ?? "")
                            ) {
                                toggleSelection(essay)
                            }
                        }
                    }
                }
                
                // Export button
                Section {
                    Button {
                        generateBook()
                    } label: {
                        HStack {
                            Image(systemName: exportFormat == .pdf ? "book.fill" : "doc.text.fill")
                            Text("Create \(exportFormat.rawValue) Book".localized)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCount > 0 ? themeManager.accent : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedCount == 0)
                }
            }
            .navigationTitle("Create Book".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPDFPreview) {
                if let data = pdfData {
                    PDFPreviewSheet(pdfData: data, title: bookTitle)
                }
            }
        }
        .task {
            await loadEssays()
        }
    }
    
    private func loadEssays() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            essays = try await FirebaseService.shared.getUserEssays(userId: userId)
                .filter { !$0.isDraft }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Error loading essays: \(error)")
        }
        
        isLoading = false
    }
    
    private func toggleSelection(_ essay: Essay) {
        if let id = essay.id {
            if selectedEssays.contains(id) {
                selectedEssays.remove(id)
            } else {
                selectedEssays.insert(id)
            }
        }
    }
    
    private func generateBook() {
        let selected = essays.filter { selectedEssays.contains($0.id ?? "") }
            .sorted { $0.createdAt < $1.createdAt }
        
        if exportFormat == .pdf {
            pdfData = PDFBookGenerator.generatePDF(
                title: bookTitle,
                essays: selected
            )
            showPDFPreview = true
        } else {
            // EPUB generation would go here
            pdfData = PDFBookGenerator.generatePDF(
                title: bookTitle,
                essays: selected
            )
            showPDFPreview = true
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}

// MARK: - Book Cover Preview

struct BookCoverPreview: View {
    let title: String
    let essayCount: Int
    let date: Date
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative elements
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.3))
                
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                
                Text("\(essayCount) essays".localized)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
    }
}

// MARK: - Essay Selection Row

struct EssaySelectionRow: View {
    let essay: Essay
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? themeManager.accent : .secondary)
                
                // Essay info
                VStack(alignment: .leading, spacing: 4) {
                    Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(essay.keyword)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(essay.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Word count
                Text("\(essay.content.count)자")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - PDF Preview Sheet

struct PDFPreviewSheet: View {
    let pdfData: Data
    let title: String
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFViewer(data: pdfData)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close".localized) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(items: [pdfData], title: title)
                }
        }
    }
}

// MARK: - PDF Viewer

struct PDFViewer: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - PDF Book Generator

class PDFBookGenerator {
    static func generatePDF(title: String, essays: [Essay]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DailyWrite",
            kCGPDFContextTitle: title
        ] as [CFString: Any]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // Letter size
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            drawCoverPage(title: title, essayCount: essays.count, in: context, pageRect: pageRect)
            
            // Table of contents
            context.beginPage()
            drawTableOfContents(essays: essays, in: context, pageRect: pageRect)
            
            // Essays
            for essay in essays {
                context.beginPage()
                drawEssay(essay: essay, in: context, pageRect: pageRect)
            }
        }
        
        return data
    }
    
    static func drawCoverPage(title: String, essayCount: Int, in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Title
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.boundingRect(with: CGSize(width: pageRect.width - 80, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        titleString.draw(in: CGRect(x: 40, y: pageRect.midY - 100, width: pageRect.width - 80, height: titleSize.height))
        
        // Subtitle
        let subtitle = "\(essayCount) essays • Created with DailyWrite"
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        subtitleString.draw(at: CGPoint(x: 40, y: pageRect.midY + 20))
        
        // Date
        let dateString = Date().formatted(date: .long, time: .omitted)
        let dateAttrString = NSAttributedString(string: dateString, attributes: subtitleAttributes)
        dateAttrString.draw(at: CGPoint(x: 40, y: pageRect.midY + 50))
    }
    
    static func drawTableOfContents(essays: [Essay], in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let entryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        
        // Title
        "Table of Contents".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
        
        // Entries
        var yPosition: CGFloat = 100
        for (index, essay) in essays.enumerated() {
            let title = essay.title.isEmpty ? "Untitled" : essay.title
            let entry = "\(index + 1). \(title)"
            entry.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: entryAttributes)
            yPosition += 30
        }
    }
    
    static func drawEssay(essay: Essay, in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let keywordAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.label
        ]
        
        // Keyword
        "Prompt: \(essay.keyword)".draw(at: CGPoint(x: 40, y: 40), withAttributes: keywordAttributes)
        
        // Title
        let title = essay.title.isEmpty ? "Untitled" : essay.title
        title.draw(at: CGPoint(x: 40, y: 70), withAttributes: titleAttributes)
        
        // Date
        let date = essay.createdAt.formatted(date: .long, time: .omitted)
        date.draw(at: CGPoint(x: 40, y: 100), withAttributes: dateAttributes)
        
        // Content
        let contentRect = CGRect(x: 40, y: 130, width: pageRect.width - 80, height: pageRect.height - 170)
        essay.content.draw(in: contentRect, withAttributes: bodyAttributes)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let title: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.title = title
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    BookExportView()
}
