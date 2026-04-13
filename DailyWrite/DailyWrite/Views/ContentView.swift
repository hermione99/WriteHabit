import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @State private var showLanguageSelector = false
    @State private var needsUsernameSetup = false
    @State private var showEditProfile = false
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if showLanguageSelector {
                LanguageSelectorView(showLanguageSelector: $showLanguageSelector)
            } else if needsUsernameSetup {
                UsernameSetupView(isAuthenticated: $isAuthenticated)
            } else if isAuthenticated {
                MainTabView(selectedTab: $selectedTab, showEditProfile: $showEditProfile)
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView()
                    }
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
            } else {
                AuthView(isAuthenticated: $isAuthenticated)
            }
        }
        .onAppear {
            checkAuthState()
        }
        .onChange(of: Auth.auth().currentUser) { _, user in
            if let user = user {
                isAuthenticated = true
                checkIfNeedsUsernameSetup(userId: user.uid)
            } else {
                isAuthenticated = false
                needsUsernameSetup = false
            }
        }
    }
    
    private func checkAuthState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            showLanguageSelector = !languageManager.hasSelectedLanguage
            if !showLanguageSelector {
                checkIfNeedsUsernameSetup(userId: user.uid)
            }
        } else {
            isAuthenticated = false
            needsUsernameSetup = false
        }
    }
    
    private func checkIfNeedsUsernameSetup(userId: String) {
        // Show main UI first, check username in background
        needsUsernameSetup = false // Assume false initially
        
        Task {
            do {
                let profile = try await FirebaseService.shared.getUserProfile(userId: userId)
                await MainActor.run {
                    if let profile = profile {
                        needsUsernameSetup = profile.username.isEmpty
                    } else {
                        needsUsernameSetup = true
                    }
                }
            } catch {
                // On error, assume needs setup to be safe
                await MainActor.run {
                    needsUsernameSetup = true
                }
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var showEditProfile: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyPromptView()
                .tabItem {
                    Label("Write".localized, systemImage: "pencil")
                }
                .tag(0)
            
            FeedView()
                .tabItem {
                    Label("Feed".localized, systemImage: "newspaper")
                }
                .tag(1)
            
            ProfileView(userId: nil)
                .tabItem {
                    Label("Profile".localized, systemImage: "person")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageManager.shared)
}
