import SwiftUI
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "ko"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .korean:
            return "한국어"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .korean:
            return "🇰🇷"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage = .korean
    @Published var hasSelectedLanguage: Bool = false
    
    private let languageKey = "selectedLanguage"
    private let hasSelectedKey = "hasSelectedLanguage"
    
    init() {
        // Check if user has already selected a language
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
            hasSelectedLanguage = true
        }
        
        // Set the app's language
        updateLanguage(currentLanguage)
    }
    
    func selectLanguage(_ language: AppLanguage) {
        currentLanguage = language
        hasSelectedLanguage = true
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        UserDefaults.standard.set(true, forKey: hasSelectedKey)
        updateLanguage(language)
    }
    
    private func updateLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
