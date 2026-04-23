import SwiftUI

struct LanguageSelectorView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Binding var showLanguageSelector: Bool
    
    var body: some View {
        // Auto-select Korean and dismiss immediately
        Color.clear
            .onAppear {
                // Force Korean and skip this screen
                languageManager.selectLanguage(.korean)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showLanguageSelector = false
                    }
                }
            }
    }
}

#Preview {
    LanguageSelectorView(showLanguageSelector: .constant(true))
}
