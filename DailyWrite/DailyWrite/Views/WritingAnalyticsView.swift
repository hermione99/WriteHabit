import SwiftUI
import Charts
import FirebaseAuth

struct WritingAnalyticsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var essays: [Essay] = []
    @State private var selectedTimeRange: TimeRange = .month
    @State private var isLoading = true
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var totalWords: Int {
        // Filter out deleted essays
        let nonDeletedEssays = essays.filter { $0.deletedAt == nil }
        return nonDeletedEssays.reduce(0) { $0 + $1.content.filter { !$0.isWhitespace }.count }
    }
    
    var totalEssays: Int {
        // Filter out deleted essays
        return essays.filter { $0.deletedAt == nil }.count
    }
    
    var averageWordsPerEssay: Int {
        totalEssays > 0 ? totalWords / totalEssays : 0
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var writingDays: Set<Date> {
        // Filter out deleted essays
        let nonDeletedEssays = essays.filter { $0.deletedAt == nil }
        return Set(nonDeletedEssays.map { Calendar.current.startOfDay(for: $0.createdAt) })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range".localized, selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue.localized).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _ in
                        Task {
                            await loadAnalytics()
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Stats cards
                        StatsGridView(
                            totalWords: totalWords,
                            totalEssays: totalEssays,
                            averageWords: averageWordsPerEssay,
                            currentStreak: currentStreak
                        )
                        
                        // Writing activity chart
                        WritingActivityChart(essays: essays, days: writingDays)
                            .frame(height: 200)
                            .padding(.horizontal)
                        
                        // Weekly pattern
                        WeeklyPatternView(essays: essays)
                            .padding(.horizontal)
                        
                        // Best writing day
                        if let bestDay = findBestWritingDay() {
                            BestDayCard(day: bestDay.day, count: bestDay.count)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Writing Analytics".localized)
        }
        .task {
            await loadAnalytics()
        }
    }
    
    private func loadAnalytics() async {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            let allEssays = try await FirebaseService.shared.getUserEssays(userId: userId)
            
            // Filter by time range
            let calendar = Calendar.current
            let now = Date()
            
            essays = allEssays.filter { essay in
                switch selectedTimeRange {
                case .week:
                    return calendar.isDate(essay.createdAt, equalTo: now, toGranularity: .weekOfYear)
                case .month:
                    return calendar.isDate(essay.createdAt, equalTo: now, toGranularity: .month)
                case .year:
                    return calendar.isDate(essay.createdAt, equalTo: now, toGranularity: .year)
                case .all:
                    return true
                }
            }.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("Error loading analytics: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let sortedDays = writingDays.sorted(by: >)
        
        guard !sortedDays.isEmpty else { return 0 }
        
        var streak = 1
        var previousDay = sortedDays[0]
        
        for day in sortedDays.dropFirst() {
            if calendar.isDate(day, equalTo: calendar.date(byAdding: .day, value: -1, to: previousDay)!, toGranularity: .day) {
                streak += 1
                previousDay = day
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func findBestWritingDay() -> (day: String, count: Int)? {
        let calendar = Calendar.current
        // Filter out deleted essays
        let nonDeletedEssays = essays.filter { $0.deletedAt == nil }
        let weekdayCounts = nonDeletedEssays.reduce(into: [Int: Int]()) { counts, essay in
            let weekday = calendar.component(.weekday, from: essay.createdAt)
            counts[weekday, default: 0] += 1
        }
        
        guard let best = weekdayCounts.max(by: { $0.value < $1.value }) else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == .korean ? "ko_KR" : "en_US")
        formatter.dateFormat = "EEEE"
        
        var dateComponents = DateComponents()
        dateComponents.weekday = best.key
        if let date = calendar.date(from: dateComponents) {
            return (formatter.string(from: date), best.value)
        }
        
        return nil
    }
}

// MARK: - Stats Grid

struct StatsGridView: View {
    let totalWords: Int
    let totalEssays: Int
    let averageWords: Int
    let currentStreak: Int
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Total Words".localized,
                value: "\(totalWords)",
                icon: "textformat",
                color: .blue
            )
            
            StatCard(
                title: "Essays Written".localized,
                value: "\(totalEssays)",
                icon: "doc.text",
                color: .green
            )
            
            StatCard(
                title: "Avg Words/Essay".localized,
                value: "\(averageWords)",
                icon: "number",
                color: .orange
            )
            
            StatCard(
                title: "Day Streak".localized,
                value: "\(currentStreak)",
                icon: "flame.fill",
                color: .red
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(hex: "FDFBF7"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Writing Activity Chart

struct WritingActivityChart: View {
    let essays: [Essay]
    let days: Set<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Writing Activity".localized)
                .font(.headline)
            
            // Simple bar chart using HStack
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(getLast30Days(), id: \.self) { date in
                        DayBar(
                            date: date,
                            count: essays.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }.count,
                            isToday: Calendar.current.isDateInToday(date)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(hex: "FDFBF7"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getLast30Days() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).compactMap { day in
            calendar.date(byAdding: .day, value: -day, to: today)
        }.reversed()
    }
}

struct DayBar: View {
    let date: Date
    let count: Int
    let isToday: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForCount(count))
                .frame(width: 8, height: CGFloat(min(count * 15 + 4, 60)))
            
            Text(dayLabel)
                .font(.system(size: 8))
                .foregroundStyle(isToday ? themeManager.accent : .secondary)
        }
    }
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    func colorForCount(_ count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.3) }
        if count == 1 { return themeManager.accent.opacity(0.6) }
        return themeManager.accent
    }
}

// MARK: - Weekly Pattern

struct WeeklyPatternView: View {
    let essays: [Essay]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Pattern".localized)
                .font(.headline)
            
            let pattern = calculateWeeklyPattern()
            
            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    DayIndicator(
                        day: weekdayLabel(for: index),
                        count: pattern[index] ?? 0
                    )
                }
            }
        }
        .padding()
        .background(Color(hex: "FDFBF7"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func calculateWeeklyPattern() -> [Int: Int] {
        let calendar = Calendar.current
        return essays.reduce(into: [Int: Int]()) { result, essay in
            let weekday = calendar.component(.weekday, from: essay.createdAt) - 1
            result[weekday, default: 0] += 1
        }
    }
    
    private func weekdayLabel(for index: Int) -> String {
        let labels = LanguageManager.shared.currentLanguage == .korean 
            ? ["일", "월", "화", "수", "목", "금", "토"]
            : ["S", "M", "T", "W", "T", "F", "S"]
        return labels[index]
    }
}

struct DayIndicator: View {
    let day: String
    let count: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 6) {
            Text(day)
                .font(.caption.weight(.medium))
                .foregroundStyle(count > 0 ? .primary : .secondary)
            
            Circle()
                .fill(count > 0 ? themeManager.accent.opacity(min(Double(count) * 0.2 + 0.3, 1.0)) : Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Best Day Card

struct BestDayCard: View {
    let day: String
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Best Writing Day".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("You write most on \(day)s".localized)
                    .font(.headline)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    WritingAnalyticsView()
}
