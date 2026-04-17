import SwiftUI

struct FontListView: View {
    @StateObject private var fontManager = FontManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let fonts: [AppFont] = AppFont.allCases
    
    var body: some View {
        List {
            Section {
                ForEach(fonts) { font in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(font.displayName)
                                .font(font.font(size: 17))
                            Text("Aa")
                                .font(font.font(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if fontManager.currentFont == font {
                            Image(systemName: "checkmark")
                                .foregroundStyle(themeManager.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        fontManager.setFont(font)
                    }
                }
            }
            
            Section("Font Size".localized) {
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
                
                HStack {
                    Spacer()
                    Text("\(Int(fontManager.writingFontSize))pt")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            Section("Preview".localized) {
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(fontManager.currentFont.font(size: fontManager.writingFontSize))
            }
        }
        .navigationTitle("Choose Font".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FontListView()
    }
}
