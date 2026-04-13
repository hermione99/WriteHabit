import SwiftUI
import FirebaseAuth

struct DailyPromptView: View {
    @State private var isWriting = false
    @State private var userStats: UserStats?
    @State private var dailyKeyword: String = ""
    @State private var monthlyActivity: [Date: Bool] = [:]
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var fontManager = FontManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section with streak
                    VStack(spacing: 16) {
                        // Streak badge
                        if let stats = userStats, stats.streakDays > 0 {
                            StreakBadgeView(days: stats.streakDays)
                        } else {
                            StreakBadgeView(days: 0)
                        }
                        
                        Text("Today's Keyword".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(dailyKeyword)
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Writing button
                    Button {
                        isWriting = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil.line")
                            Text("Start Writing".localized)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    // Monthly streak calendar
                    MonthlyStreakView(activity: monthlyActivity)
                        .padding(.horizontal)
                        .id(languageManager.currentLanguage.rawValue + "_" + UUID().uuidString)
                    
                    // Stats
                    HStack(spacing: 40) {
                        StatView(value: "\(userStats?.totalWords ?? 0)", label: "Words Written".localized)
                        StatView(value: "\(userStats?.essayCount ?? 0)", label: "Published".localized)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
            }
            .fullScreenCover(isPresented: $isWriting) {
                NavigationStack {
                    SimpleWritingEditorView(keyword: dailyKeyword)
                }
            }
        }
        .task {
            await loadDailyKeyword()
            await loadUserStats()
            await loadMonthlyActivity()
        }
    }
    
    private func loadDailyKeyword() async {
        dailyKeyword = await KeywordGenerator.shared.getDailyKeyword(language: languageManager.currentLanguage)
    }
    
    private func loadUserStats() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            let essayCount = essays.count
            let totalWords = essays.reduce(0) { $0 + $1.content.count }
            let streakDays = calculateStreak(from: essays)
            userStats = UserStats(essayCount: essayCount, streakDays: streakDays, totalWords: totalWords)
        } catch {
            print("Error loading user stats: \(error)")
        }
    }
    
    private func loadMonthlyActivity() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -29, to: endDate)!
            
            let essays = try await FirebaseService.shared.getUserEssaysInDateRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            
            var activity: [Date: Bool] = [:]
            for essay in essays {
                let day = calendar.startOfDay(for: essay.createdAt)
                activity[day] = true
            }
            monthlyActivity = activity
        } catch {
            print("Error loading monthly activity: \(error)")
        }
    }
    
    private func calculateStreak(from essays: [Essay]) -> Int {
        guard !essays.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedEssays = essays.sorted { $0.createdAt > $1.createdAt }
        var streak = 0
        var currentDate = Date()
        
        for essay in sortedEssays {
            let essayDate = calendar.startOfDay(for: essay.createdAt)
            let today = calendar.startOfDay(for: currentDate)
            
            if calendar.isDate(essayDate, inSameDayAs: today) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: today)!
            } else if calendar.isDate(essayDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
                streak += 1
                currentDate = essayDate
            } else {
                break
            }
        }
        
        return streak
    }
}

struct UserStats {
    let essayCount: Int
    let streakDays: Int
    let totalWords: Int
}

struct StreakBadgeView: View {
    let days: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(radius: 4)
                
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    
                    Text("\(days)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            Text(days == 1 ? "Day Streak".localized : "Day Streak".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct MonthlyStreakView: View {
    let activity: [Date: Bool]
    let calendar = Calendar.current
    @StateObject private var languageManager = LanguageManager.shared
    
    private var last30Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        var days: [Date] = []
        for i in (0...29).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days".localized)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Grid of 30 days (6 rows x 5 columns)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(last30Days, id: \.self) { date in
                    let dayStart = calendar.startOfDay(for: date)
                    let hasActivity = activity.keys.contains { calendar.isDate($0, inSameDayAs: dayStart) }
                    StreakDayCell(
                        date: date,
                        hasActivity: hasActivity,
                        isToday: calendar.isDateInToday(date)
                    )
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 12, height: 12)
                    Text("Written".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Text("Missed".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StreakDayCell: View {
    let date: Date
    let hasActivity: Bool
    let isToday: Bool
    let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(hasActivity ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                .frame(height: 28)
            
            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(height: 28)
            }
        }
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DailyPromptView()
}
