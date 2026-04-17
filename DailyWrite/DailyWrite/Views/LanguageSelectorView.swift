import SwiftUI

struct LanguageSelectorView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Binding var showLanguageSelector: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedLanguage: AppLanguage = .korean
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(themeManager.accent)
                    
                    Text("DailyWrite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose your preferred language".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Language options
                VStack(spacing: 16) {
                    ForEach(AppLanguage.allCases) { language in
                        LanguageOptionButton(
                            language: language,
                            isSelected: selectedLanguage == language,
                            action: {
                                selectedLanguage = language
                            }
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Continue button
                Button {
                    languageManager.selectLanguage(selectedLanguage)
                    withAnimation {
                        showLanguageSelector = false
                    }
                } label: {
                    Text("Continue".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                
                Text("You can change this later in settings".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            }
        }
    }
}

struct LanguageOptionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.flag)
                    .font(.title2)
                
                Text(language.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accent)
                        .font(.title3)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(isSelected ? themeManager.accent.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.accent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LanguageSelectorView(showLanguageSelector: .constant(true))
}
