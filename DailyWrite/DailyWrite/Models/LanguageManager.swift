import SwiftUI
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "ko"
    
    var id: String { rawValue }
    
    var displayName: String {
        return "한국어"
    }
    
    var flag: String {
        return "🇰🇷"
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage = .korean
    @Published var hasSelectedLanguage: Bool = false
    
    private let languageKey = "selectedLanguage"
    private let hasSelectedKey = "hasSelectedLanguage"
    
    init() {
        // Force Korean language (English disabled for now)
        currentLanguage = .korean
        hasSelectedLanguage = true
        updateLanguage(.korean)
    }
    
    func selectLanguage(_ language: AppLanguage) {
        // Only Korean is supported for now
        currentLanguage = .korean
        hasSelectedLanguage = true
        UserDefaults.standard.set("ko", forKey: languageKey)
        UserDefaults.standard.set(true, forKey: hasSelectedKey)
        updateLanguage(.korean)
    }
    
    private func updateLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
