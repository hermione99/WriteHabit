import SwiftUI

struct ThemePickerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        themeManager.setTheme(theme)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: theme.icon)
                                .font(.title2)
                                .foregroundStyle(theme == themeManager.currentTheme ? .blue : .secondary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.displayName.localized)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("Choose your preferred appearance. The paper texture will adapt to match light or dark mode.".localized)
            }
            
            // Preview
            Section("Preview".localized) {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Aa")
                                .font(.largeTitle)
                            Text("Sample Text")
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(ThemeColors.paperBackground(for: effectiveColorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.paperLines(for: effectiveColorScheme), lineWidth: 1)
                    )
                }
            }
        }
        .navigationTitle("Appearance".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done".localized) {
                    dismiss()
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
    
    var effectiveColorScheme: ColorScheme {
        switch themeManager.currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemColorScheme
        }
    }
}

#Preview {
    NavigationStack {
        ThemePickerView()
    }
}
