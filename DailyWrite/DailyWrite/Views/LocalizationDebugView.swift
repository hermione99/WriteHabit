import SwiftUI

struct LocalizationDebugView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var debugOutput = ""
    
    let testStrings = [
        "Settings",
        "Profile",
        "Heading",
        "Subheading",
        "Make public",
        "Writing Archive",
        "Today's Keyword",
        "Start Writing",
        "Edit Profile"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Language") {
                    Text("Current: \(languageManager.currentLanguage.displayName) (\(languageManager.currentLanguage.rawValue))")
                    
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            languageManager.selectLanguage(lang)
                            runDebug()
                        } label: {
                            HStack {
                                Text(lang.flag)
                                Text(lang.displayName)
                                Spacer()
                                if languageManager.currentLanguage == lang {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("Test Results") {
                    ForEach(testStrings, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(key.localized)
                                .font(.body)
                        }
                    }
                }
                
                Section("Bundle Debug") {
                    Text(debugOutput)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("Run Debug") {
                        runDebug()
                    }
                }
            }
            .navigationTitle("Localization Debug")
            .onAppear {
                runDebug()
            }
        }
    }
    
    func runDebug() {
        let language = languageManager.currentLanguage.rawValue
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        let exists = path != nil ? FileManager.default.fileExists(atPath: path!) : false
        
        var output = ""
        output += "Language: \(language)\n"
        output += "Path: \(path ?? "nil")\n"
        output += "Exists: \(exists)\n"
        
        if let p = path, let bundle = Bundle(path: p) {
            output += "Bundle loaded: yes\n"
            
            // Try to read Settings string
            let settings = NSLocalizedString("Settings", tableName: nil, bundle: bundle, comment: "")
            output += "Settings lookup: '\(settings)'\n"
        } else {
            output += "Bundle loaded: no\n"
        }
        
        debugOutput = output
    }
}

#Preview {
    LocalizationDebugView()
}
