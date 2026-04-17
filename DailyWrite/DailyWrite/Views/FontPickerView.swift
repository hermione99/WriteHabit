import SwiftUI

struct FontPickerView: View {
    @StateObject private var fontManager = FontManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var previewText = "The quick brown fox jumps over the lazy dog.\n다람쥐 헌 쳇바퀴에 타고파."
    
    let englishFonts: [AppFont] = [.system, .serif, .rounded, .monospaced, .georgia, .courier]
    let koreanFonts: [AppFont] = [.appleSDGothic, .nanumMyeongjo, .nanumGothic, .koPubBatang, .koPubDotum, .pretendard, .ridiBatang]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview area
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $previewText)
                        .font(fontManager.currentFont.font(size: fontManager.writingFontSize))
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(height: 120)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Font size slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $fontManager.writingFontSize, in: 14...32, step: 1)
                            .onChange(of: fontManager.writingFontSize) {
                                fontManager.setFontSize(fontManager.writingFontSize)
                            }
                        Image(systemName: "textformat.size.larger")
                    }
                    Text("\(Int(fontManager.writingFontSize))pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Divider()
                
                // Font list
                List {
                    Section("English Fonts".localized) {
                        ForEach(englishFonts) { font in
                            FontRow(font: font, isSelected: fontManager.currentFont == font)
                        }
                    }
                    
                    Section("Korean Fonts".localized) {
                        ForEach(koreanFonts) { font in
                            FontRow(font: font, isSelected: fontManager.currentFont == font)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Choose Font".localized)
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

struct FontRow: View {
    let font: AppFont
    let isSelected: Bool
    @StateObject private var fontManager = FontManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button {
            fontManager.setFont(font)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(font.font(size: 17))
                        .foregroundStyle(.primary)
                    
                    Text(sampleText(for: font))
                        .font(font.font(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func sampleText(for font: AppFont) -> String {
        if font.isKoreanFont {
            return "안녕하세요 다람쥐 헌 쳇바퀴"
        } else {
            return "The quick brown fox"
        }
    }
}

#Preview {
    FontPickerView()
}
