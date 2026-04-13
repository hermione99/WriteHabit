import SwiftUI

struct LanguageTestView: View {
    @State private var currentLang = ""
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Current State") {
                    Text("Language: \(currentLang)")
                    Text("Saved: \(UserDefaults.standard.string(forKey: "selectedLanguage") ?? "nil")")
                }
                
                Section("Test Strings") {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                    }
                }
                
                Section("Actions") {
                    Button("Set to Korean") {
                        LanguageManager.shared.selectLanguage(.korean)
                        refresh()
                    }
                    
                    Button("Set to English") {
                        LanguageManager.shared.selectLanguage(.english)
                        refresh()
                    }
                    
                    Button("Clear UserDefaults") {
                        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
                        UserDefaults.standard.removeObject(forKey: "hasSelectedLanguage")
                        refresh()
                    }
                    
                    Button("Refresh") {
                        refresh()
                    }
                }
            }
            .navigationTitle("Language Test")
            .onAppear {
                refresh()
            }
        }
    }
    
    func refresh() {
        currentLang = LanguageManager.shared.currentLanguage.rawValue
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "nil"
        
        testResults = [
            "Settings -> \("Settings".localized)",
            "Heading -> \("Heading".localized)",
            "Make public -> \("Make public".localized)",
            "Profile -> \("Profile".localized)"
        ]
    }
}

#Preview {
    LanguageTestView()
}
