import SwiftUI

struct LocalizationTestView: View {
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Current Language") {
                    Text("Language: \(languageManager.currentLanguage.displayName)")
                    Text("Code: \(languageManager.currentLanguage.rawValue)")
                }
                
                Section("Test Strings") {
                    Text("Settings".localized)
                    Text("Profile".localized)
                    Text("Today's Keyword".localized)
                    Text("Start Writing".localized)
                    Text("Edit Profile".localized)
                    Text("Writing Archive".localized)
                    Text("Heading".localized)
                    Text("Subheading".localized)
                    Text("Sub-subheading".localized)
                    Text("Body".localized)
                }
                
                Section("Switch Language") {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            languageManager.selectLanguage(language)
                        } label: {
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                                Spacer()
                                if languageManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Localization Test")
        }
    }
}

#Preview {
    LocalizationTestView()
}
