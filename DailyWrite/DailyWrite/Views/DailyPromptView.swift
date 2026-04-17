import SwiftUI
import FirebaseAuth

struct DailyPromptView: View {
    @State private var isWriting = false
    @State private var dailyKeyword: String = ""
    @State private var writingDates: [Date] = []
    @State private var currentStreak: Int = 0
    @State private var selectedDate: Date? = nil
    @State private var showingEssayDetail = false
    @State private var selectedEssay: Essay? = nil
    @StateObject private var languageManager = LanguageManager.shared
    
    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Large Date Display
                VStack(alignment: .leading, spacing: 4) {
                    // Date number and day of week together
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(calendar.component(.day, from: Date()))")
                            .font(.system(size: 120, weight: .bold, design: .default))
                            .foregroundStyle(.primary)
                        
                        Text(dayString(from: Date()))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 12)
                    }
                    
                    // Month/Year below
                    Text(monthYearString(from: Date()))
                        .font(.system(size: 18, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Center - Today's Prompt
                VStack(spacing: 12) {
                    Text("Today's Prompt".localized)
                        .font(.system(size: 13, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(2)
                        .foregroundStyle(.secondary)
                    
                    Text(dailyKeyword)
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Dot Calendar
                VStack(spacing: 16) {
                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar grid - 5 rows x 7 columns
                    DotCalendarGrid(writingDates: writingDates) { date in
                        Task {
                            await loadEssayForDate(date)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Write Button
                Button {
                    isWriting = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                        Text("Write".localized)
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(.primary)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .fullScreenCover(isPresented: $isWriting) {
                NavigationStack {
                    SimpleWritingEditorView(keyword: dailyKeyword)
                }
            }
            .sheet(item: $selectedEssay) { essay in
                NavigationStack {
                    EssayDetailView(essay: essay)
                        .navigationTitle("Essay".localized)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done".localized) {
                                    selectedEssay = nil
                                }
                            }
                        }
                }
            }
        }
        .task {
            await loadDailyKeyword()
            await loadWritingDates()
            await loadStreak()
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage == .korean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage == .korean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func loadDailyKeyword() async {
        dailyKeyword = await KeywordGenerator.shared.getDailyKeyword(language: languageManager.currentLanguage)
    }
    
    private func loadWritingDates() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            writingDates = essays.filter { !$0.isDraft }.map { $0.createdAt }
        } catch {
            print("Error loading writing dates: \(error)")
        }
    }
    
    private func loadStreak() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            currentStreak = calculateCurrentStreak(from: essays)
        } catch {
            print("Error loading streak: \(error)")
        }
    }
    
    private func calculateCurrentStreak(from essays: [Essay]) -> Int {
        let publishedEssays = essays.filter { !$0.isDraft }
        guard !publishedEssays.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = publishedEssays.map { $0.createdAt }.sorted(by: >)
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        if !calendar.isDate(sortedDates[0], inSameDayAs: checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  calendar.isDate(sortedDates[0], inSameDayAs: yesterday) else {
                return 0
            }
        }
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else if date < checkDate {
                break
            }
        }
        
        return streak
    }
    
    private func loadEssayForDate(_ date: Date) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Get essays for the date range
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let essays = try await FirebaseService.shared.getUserEssaysInDateRange(
                userId: userId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            
            await MainActor.run {
                if let essay = essays.first(where: { !$0.isDraft }) {
                    selectedEssay = essay
                    showingEssayDetail = true
                } else if let draft = essays.first(where: { $0.isDraft }) {
                    selectedEssay = draft
                    showingEssayDetail = true
                }
            }
        } catch {
            print("Error loading essay for date: \(error)")
        }
    }
}

// MARK: - Monthly Calendar Grid

struct DotCalendarGrid: View {
    let writingDates: [Date]
    let onDateTap: (Date) -> Void
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        // Calendar grid - weekday headers are shown above this view
        let days = getCurrentMonthDays()
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    DayDot(
                        date: date,
                        isWritten: hasWritten(on: date),
                        isToday: calendar.isDateInToday(date),
                        onTap: { onDateTap(date) }
                    )
                } else {
                    // Empty slot
                    DayDot(date: nil, isWritten: false, isToday: false, onTap: nil)
                }
            }
        }
    }
    
    private func getCurrentMonthDays() -> [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday = 1
        
        let today = calendar.startOfDay(for: Date())
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return [] }
        
        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var days: [Date?] = []
        
        // Add empty slots for days before the first of the month
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        var currentDate = firstDayOfMonth
        while currentDate <= lastDayOfMonth {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // Pad to complete the grid (fill remaining slots in the last week)
        let remainingSlots = (7 - (days.count % 7)) % 7
        for _ in 0..<remainingSlots {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasWritten(on date: Date) -> Bool {
        writingDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}

struct DayDot: View {
    let date: Date?
    let isWritten: Bool
    let isToday: Bool
    
    // Retro Sunset palette colors
    private let submittedColor = Color(red: 0.027, green: 0.580, blue: 0.580) // #069494 teal
    private let missedColor = Color(red: 0.718, green: 0.255, blue: 0.055)   // #B7410E burnt orange
    private let futureColor = Color(.systemGray5) // Gray for future days
    private let todayBorderColor = Color(red: 1.0, green: 0.808, blue: 0.106) // #FFCE1B golden yellow
    
    private var isPast: Bool {
        guard let date = date else { return false }
        return Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
    
    private var onTap: (() -> Void)? = nil
    
    init(date: Date?, isWritten: Bool, isToday: Bool, onTap: (() -> Void)? = nil) {
        self.date = date
        self.isWritten = isWritten
        self.isToday = isToday
        self.onTap = onTap
    }
    
    var body: some View {
        if let date = date {
            ZStack {
                // Background circle - teal for submitted, burnt orange for missed past days, gray for future
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                // Golden yellow border for today
                if isToday {
                    Circle()
                        .stroke(todayBorderColor, lineWidth: 3)
                        .frame(width: 36, height: 36)
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                if isWritten, let onTap = onTap {
                    onTap()
                }
            }
        } else {
            // Empty slot
            Circle()
                .fill(Color.clear)
                .frame(width: 36, height: 36)
        }
    }
    
    private var backgroundColor: Color {
        if isWritten {
            return submittedColor
        } else if isPast {
            return missedColor
        } else {
            return futureColor
        }
    }
}

#Preview {
    DailyPromptView()
}
