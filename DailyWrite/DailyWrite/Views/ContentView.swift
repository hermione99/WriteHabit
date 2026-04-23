import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @State private var showLanguageSelector = false
    @State private var needsUsernameSetup = false
    @State private var showEditProfile = false
    @State private var navigateToEssayId: String? = nil
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showNotificationPrompt = false
    @State private var showNotificationTimeSetup = false
    // For handling notification taps
    @State private var showWritingEditorFromNotification = false
    @State private var showFriendsFromNotification = false
    
    var body: some View {
        Group {
            if showLanguageSelector {
                LanguageSelectorView(showLanguageSelector: $showLanguageSelector)
            } else if needsUsernameSetup {
                UsernameSetupView(isAuthenticated: $isAuthenticated, needsUsernameSetup: $needsUsernameSetup)
            } else if isAuthenticated {
                MainTabView(selectedTab: $selectedTab, showEditProfile: $showEditProfile, navigateToEssayId: $navigateToEssayId, onSignOut: {
                    isAuthenticated = false
                })
                    .sheet(isPresented: $showEditProfile) {
                        EditProfileView()
                    }
                    .preferredColorScheme(.light)
            } else {
                AuthView(isAuthenticated: $isAuthenticated)
            }
        }
        .onAppear {
            checkAuthState()
            setupNotificationObserver()
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
        .alert("Daily Writing Reminder".localized, isPresented: $showNotificationPrompt) {
            Button("Not Now".localized, role: .cancel) {
                UserDefaults.standard.set(true, forKey: "notificationPromptShown")
            }
            Button("Enable".localized) {
                UserDefaults.standard.set(true, forKey: "notificationPromptShown")
                Task {
                    let granted = await notificationService.requestAuthorization()
                    if granted {
                        notificationService.isReminderEnabled = true
                        // Show time setup sheet
                        showNotificationTimeSetup = true
                    }
                }
            }
        } message: {
            Text("Would you like to receive daily reminders to write? You can change this anytime in Settings.".localized)
        }
        .sheet(isPresented: $showNotificationTimeSetup) {
            NotificationSettingsView()
        }
        .fullScreenCover(isPresented: $showWritingEditorFromNotification) {
            SimpleWritingEditorView(keyword: KeywordsService.shared.getStableKeyword(for: Date(), language: .korean))
        }
        .sheet(isPresented: $showFriendsFromNotification) {
            FriendsView()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func setupNotificationObserver() {
        // Navigate to Essay
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToEssay"),
            object: nil,
            queue: .main
        ) { notification in
            if let essayId = notification.userInfo?["essayId"] as? String {
                navigateToEssayId = essayId
                selectedTab = 3 // Feed tab
            }
        }
        
        // Open Writing Editor (from daily reminder)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenWritingEditor"),
            object: nil,
            queue: .main
        ) { _ in
            showWritingEditorFromNotification = true
        }
        
        // Open Friends (from friend request notification)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenFriends"),
            object: nil,
            queue: .main
        ) { _ in
            showFriendsFromNotification = true
        }
    }
    
    private func checkAuthState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            showLanguageSelector = !languageManager.hasSelectedLanguage
            if !showLanguageSelector {
                checkIfNeedsUsernameSetup(userId: user.uid)
                // Check if we should show notification prompt
                checkAndShowNotificationPrompt()
            }
        } else {
            isAuthenticated = false
            needsUsernameSetup = false
        }
    }
    
    private func checkAndShowNotificationPrompt() {
        // Only show if user hasn't been asked before and hasn't authorized notifications
        let hasPrompted = UserDefaults.standard.bool(forKey: "notificationPromptShown")
        if !hasPrompted && !notificationService.isAuthorized {
            // Small delay to let the UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showNotificationPrompt = true
            }
        }
    }
    
    private func checkIfNeedsUsernameSetup(userId: String) {
        needsUsernameSetup = false
        
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
    @Binding var navigateToEssayId: String?
    var onSignOut: (() -> Void)? = nil
    @StateObject private var friendsService = FriendsService.shared
    @State private var isWriting = false
    @State private var todayKeyword: String = ""
    @State private var dailyKeyword: String = ""
    
    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    StreaksView()
                case 2:
                    Color.clear
                case 3:
                    FeedView(navigateToEssayId: $navigateToEssayId)
                case 4:
                    ProfileView(userId: nil, onSignOut: onSignOut)
                        .badge(friendsService.pendingRequests.count)
                default:
                    HomeView()
                }
            }
            
            VStack {
                Spacer()
                customTabBar
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .fullScreenCover(isPresented: $isWriting) {
            SimpleWritingEditorView(keyword: todayKeyword.isEmpty ? computeTodayKeyword() : todayKeyword)
        }
        .onAppear {
            friendsService.startListeningForRequests()
            loadTodayKeyword()
        }
        .onDisappear {
            friendsService.stopListeningForRequests()
        }
    }
    
    private var customTabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(index: 0, icon: "house", label: "Home")
                tabButton(index: 1, icon: "flame", label: "Streaks")
                
                Button {
                    todayKeyword = computeTodayKeyword()
                    isWriting = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "0D244D"))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(hex: "0D244D").opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "F5F0E8"))
                    }
                }
                .frame(maxWidth: .infinity)
                
                tabButton(index: 3, icon: "newspaper", label: "Feed")
                tabButton(index: 4, icon: "person", label: "Profile")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Rectangle()
                .fill(Color(hex: "F5F0E8"))
                .frame(height: 20)
        }
        .background(Color(hex: "F5F0E8"))
    }
    
    private func tabButton(index: Int, icon: String, label: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: selectedTab == index ? .semibold : .regular))
                Text(label.localized)
                    .font(.system(size: 10, weight: selectedTab == index ? .medium : .regular))
            }
            .foregroundColor(selectedTab == index ? Color(hex: "0D244D") : Color(hex: "0D244D").opacity(0.5))
            .frame(maxWidth: .infinity)
        }
    }
    
    private func loadTodayKeyword() {
        dailyKeyword = computeTodayKeyword()
        todayKeyword = dailyKeyword
    }
    
    private func computeTodayKeyword() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        return KeywordsService.shared.getStableKeyword(for: today, language: .korean)
    }
}

struct HomeView: View {
    var body: some View {
        DailyPromptView()
    }
}

struct StreaksView: View {
    @State private var monthlyActivity: [Date: Bool] = [:]
    @State private var userStats: UserStats?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        PunchCardView(streakDays: userStats?.streakDays ?? 0)
                            .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Streaks".localized)
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            let essayCount = essays.filter { $0.deletedAt == nil }.count
            let totalWords = essays.filter { $0.deletedAt == nil }.reduce(0) { $0 + $1.wordCount }
            
            let dailyPromptEssays = essays.filter { essay in
                guard essay.deletedAt == nil else { return false }
                let calendar = Calendar.current
                let essayDay = calendar.startOfDay(for: essay.createdAt)
                let components = calendar.dateComponents([.year, .month, .day], from: essayDay)
                let year = components.year ?? 0
                let month = components.month ?? 0
                let day = components.day ?? 0
                let stableHash = ((year * 365 + month * 31 + day) * 9301 + 49297) % 233280
                let poolIndex = stableHash % 100
                let koreanPool = [
                    "봄", "여정", "추억", "꿈", "희망", "성찰", "기쁨", "도전", "성장", "평화",
                    "모험", "변화", "지혜", "감사", "경이로움", "아침", "저녁", "비", "햇살", "바다",
                    "산", "숲", "강", "별", "달", "집", "가족", "우정", "사랑", "용기"
                ]
                let expectedKeyword = koreanPool[poolIndex % koreanPool.count]
                return essay.keyword == expectedKeyword
            }
            
            let streakDays = calculateStreak(from: dailyPromptEssays)
            userStats = UserStats(essayCount: essayCount, streakDays: streakDays, totalWords: totalWords)
            
            var activity: [Date: Bool] = [:]
            let calendar = Calendar.current
            for essay in dailyPromptEssays {
                let day = calendar.startOfDay(for: essay.createdAt)
                activity[day] = true
            }
            monthlyActivity = activity
        } catch {
            print("Error loading streak data: \(error)")
        }
    }
    
    private func calculateStreak(from dailyEssays: [Essay]) -> Int {
        let calendar = Calendar.current
        let sortedDays = dailyEssays
            .map { calendar.startOfDay(for: $0.createdAt) }
            .sorted()
            .unique()
        
        guard !sortedDays.isEmpty else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let lastWriteDay = sortedDays.last!
        if lastWriteDay < yesterday {
            return 0
        }
        
        var streak = 1
        var previousDay = lastWriteDay
        
        for day in sortedDays.dropLast().reversed() {
            let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: previousDay)!
            if calendar.isDate(day, inSameDayAs: expectedPrevious) {
                streak += 1
                previousDay = day
            } else {
                break
            }
        }
        
        return streak
    }
}

struct PunchCardView: View {
    let streakDays: Int
    let totalSlots = 30
    
    // 현재 단계 (1~30)
    var displayDays: Int {
        if streakDays == 0 { return 0 }
        let remainder = streakDays % totalSlots
        return remainder == 0 ? totalSlots : remainder
    }
    
    // 완료한 세트 수
    var completedSets: Int {
        return streakDays / totalSlots
    }
    
    // 현재 슬롯에 표시할 진행도 (completedSets가 0이면 streakDays, 아니면 displayDays)
    var slotsFilled: Int {
        return displayDays
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("DAILY WRITE")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Color(hex: "0D244D").opacity(0.6))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streakDays)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "4A5A30"))
                    
                    Text("days".localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "0D244D"))
                }
                
                Text("current streak".localized)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "0D244D").opacity(0.5))
                
                if completedSets > 0 {
                    // N단계 완료 메시지
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "C2441C"))
                        
                        Text("\(completedSets)\(completedSets == 1 ? "st" : completedSets == 2 ? "nd" : completedSets == 3 ? "rd" : "th") Stage Completed!".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "C2441C"))
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "C2441C"))
                    }
                    .padding(.top, 4)
                } else if streakDays < totalSlots {
                    Text("resets when you miss the streak".localized)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "852E47").opacity(0.7))
                        .padding(.top, 4)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "C2441C"))
                        
                        Text("Challenge Completed!".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "C2441C"))
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "C2441C"))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 24)
            
            Divider()
                .background(Color(hex: "0D244D").opacity(0.1))
                .padding(.horizontal, 24)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                spacing: 16
            ) {
                ForEach(0..<totalSlots, id: \.self) { index in
                    PunchSlot(
                        index: index,
                        isPunched: index < slotsFilled,
                        isToday: index == slotsFilled - 1 && streakDays > 0
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            if streakDays >= totalSlots {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "4A5A30"))
                    
                    Text("30-Day Challenge Complete!".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "0D244D"))
                    
                    Text("Congratulations!".localized)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0D244D").opacity(0.6))
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F5F0E8"))
                        .shadow(color: Color(hex: "0D244D").opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FDFBF7"))
                .shadow(color: Color(hex: "0D244D").opacity(0.1), radius: 20, x: 0, y: 8)
        )
        .overlay(
            Circle()
                .fill(Color(hex: "C2441C").opacity(0.03))
                .frame(width: 120, height: 120)
                .offset(x: 80, y: -60)
                .blur(radius: 20)
        )
    }
}

struct PunchSlot: View {
    let index: Int
    let isPunched: Bool
    let isToday: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    isToday 
                        ? Color(hex: "D6D385")
                        : Color(hex: "0D244D").opacity(0.15),
                    lineWidth: isToday ? 3 : 1.5
                )
                .background(
                    Circle()
                        .fill(isToday ? Color(hex: "D6D385").opacity(0.1) : Color.clear)
                )
                .frame(width: 44, height: 44)
            
            if isPunched {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4A5A30"))
                        .frame(width: 40, height: 40)
                    
                    ForEach(0..<8) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Color(hex: "F5F0E8"))
                            .offset(
                                x: 16 * cos(Double(i) * .pi / 4),
                                y: 16 * sin(Double(i) * .pi / 4)
                            )
                    }
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "F5F0E8"))
                }
            } else if isToday {
                Circle()
                    .fill(Color(hex: "0D244D"))
                    .frame(width: 12, height: 12)
            }
        }
        .frame(height: 48)
    }
}

struct UserStats {
    let essayCount: Int
    let streakDays: Int
    let totalWords: Int
}

extension Array where Element == Date {
    func unique() -> [Date] {
        var seen = Set<Date>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageManager.shared)
}
