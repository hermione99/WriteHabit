import SwiftUI

// Simple font picker that should definitely work
struct SimpleFontSettingsView: View {
    @StateObject private var fontManager = FontManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let fonts: [AppFont] = AppFont.allCases
    
    var body: some View {
        NavigationStack {
            List {
                Section("Font Size") {
                    HStack {
                        Text("A")
                            .font(.caption)
                        Slider(value: $fontManager.writingFontSize, in: 14...32, step: 1)
                            .onChange(of: fontManager.writingFontSize) {
                                fontManager.setFontSize(fontManager.writingFontSize)
                            }
                        Text("A")
                            .font(.title2)
                    }
                    Text("\(Int(fontManager.writingFontSize))pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Fonts") {
                    ForEach(fonts) { font in
                        Button {
                            fontManager.setFont(font)
                        } label: {
                            HStack {
                                Text(font.displayName)
                                    .font(font.font(size: 16))
                                Spacer()
                                if fontManager.currentFont == font {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(themeManager.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section("Preview") {
                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(fontManager.currentFont.font(size: fontManager.writingFontSize))
                }
            }
            .navigationTitle("Font")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleFontSettingsView()
}
