import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct KeywordArchiveView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var essaysByDate: [String: [Essay]] = [:]
    @State private var keywordsByDate: [String: String] = [:]
    @State private var isLoading = false
    @State private var showingWritingView = false
    @State private var writingKeyword: String = ""
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Colors
    private let creamColor = Color(hex: "F5F0E8")
    private let indigoColor = Color(hex: "0D244D")
    private let mossColor = Color(hex: "4A5A30")
    private let rubyColor = Color(hex: "852E47")
    private let burntColor = Color(hex: "C2441C")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cream background
                creamColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Month header with navigation
                        monthHeader
                        
                        // Calendar card
                        calendarCard
                        
                        // Selected day detail
                        selectedDaySection
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationTitle("Writing Archive".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                    .foregroundStyle(indigoColor)
                }
            }
            .fullScreenCover(isPresented: $showingWritingView) {
                NavigationStack {
                    SimpleWritingEditorView(keyword: writingKeyword)
                }
            }
        }
        .task {
            await loadEssaysForMonth()
        }
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    Task { await loadEssaysForMonth() }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(indigoColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(hex: "FDFBF7"))
                            .shadow(color: indigoColor.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(indigoColor)
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    Task { await loadEssaysForMonth() }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(indigoColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(hex: "FDFBF7"))
                            .shadow(color: indigoColor.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
        }
    }
    
    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 16) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols(), id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(indigoColor.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            status: dayStatus(for: date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FDFBF7"))
                .shadow(color: indigoColor.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Selected Day Section
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedSelectedDate)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(indigoColor)
                    
                    if let keyword = keywordForSelectedDate {
                        HStack(spacing: 6) {
                            Text("Keyword:".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(indigoColor.opacity(0.6))
                            Text(keyword)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(indigoColor)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                if let status = dayStatus(for: selectedDate) {
                    statusBadge(status: status)
                }
            }
            
            // Essays list or empty state
            if let essays = essaysForSelectedDate, !essays.isEmpty {
                VStack(spacing: 12) {
                    ForEach(essays) { essay in
                        NavigationLink(destination: EssayDetailView(essay: essay)) {
                            ArchiveEssayCard(essay: essay)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                emptyDayView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FDFBF7"))
                .shadow(color: indigoColor.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }
    
    private var emptyDayView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(indigoColor.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 32))
                    .foregroundStyle(indigoColor.opacity(0.3))
            }
            
            Text("No essays on this day".localized)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(indigoColor.opacity(0.5))
            
            if canWrite(on: selectedDate) {
                Button {
                    writingKeyword = keywordForSelectedDate ?? ""
                    showingWritingView = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                        Text("Write now".localized)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(indigoColor)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Status Badge
    private func statusBadge(status: DayStatus) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 8, height: 8)
            Text(statusText(status))
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(statusColor(status))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor(status).opacity(0.1))
        )
    }
    
    // MARK: - Helper Types
    enum DayStatus {
        case written
        case todayEmpty
        case missed
        case future
    }
    
    // MARK: - Helper Methods
    private func dayStatus(for date: Date) -> DayStatus? {
        let today = calendar.startOfDay(for: Date())
        let date = calendar.startOfDay(for: date)
        
        if calendar.isDate(date, inSameDayAs: today) {
            return hasEssays(on: date) ? .written : .todayEmpty
        } else if date < today {
            return hasEssays(on: date) ? .written : .missed
        } else {
            return .future
        }
    }
    
    private func statusColor(_ status: DayStatus) -> Color {
        switch status {
        case .written:
            return mossColor
        case .todayEmpty:
            return indigoColor
        case .missed:
            return rubyColor
        case .future:
            return burntColor
        }
    }
    
    private func statusText(_ status: DayStatus) -> String {
        switch status {
        case .written:
            return "Written".localized
        case .todayEmpty:
            return "Today".localized
        case .missed:
            return "Missed".localized
        case .future:
            return "Upcoming".localized
        }
    }
    
    private func weekdaySymbols() -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        // Adjust for different calendar start of week
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }
    
    private var keywordForSelectedDate: String? {
        keywordsByDate[dateFormatter.string(from: selectedDate)]
    }
    
    private var essaysForSelectedDate: [Essay]? {
        essaysByDate[dateFormatter.string(from: selectedDate)]
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage.rawValue)
        formatter.dateFormat = "MMM d, EEEE"
        return formatter.string(from: selectedDate)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage.rawValue)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Pad to complete the last week
        let remainingDays = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: remainingDays))
        
        return days
    }
    
    private func hasEssays(on date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return essaysByDate[dateString]?.isEmpty == false
    }
    
    private func canWrite(on date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let date = calendar.startOfDay(for: date)
        return date <= today
    }
    
    // MARK: - Data Loading
    private func loadEssaysForMonth() async {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get date range for the month
            guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }
            
            // Load essays for this date range
            let essays = try await FirebaseService.shared.getUserEssaysInDateRange(
                userId: user.uid,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )
            
            // Group by date
            var essayDict: [String: [Essay]] = [:]
            var keywordDict: [String: String] = [:]
            
            for essay in essays {
                let dateString = dateFormatter.string(from: essay.createdAt)
                
                if essayDict[dateString] == nil {
                    essayDict[dateString] = []
                }
                essayDict[dateString]?.append(essay)
                
                // Store keyword for this date
                if keywordDict[dateString] == nil {
                    keywordDict[dateString] = essay.keyword
                }
            }
            
            // Generate keywords for all days in month
            var currentDate = monthInterval.start
            while currentDate < monthInterval.end {
                let dateString = dateFormatter.string(from: currentDate)
                if keywordDict[dateString] == nil {
                    keywordDict[dateString] = try await KeywordsService.shared.getKeywordForDate(currentDate, language: languageManager.currentLanguage)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            await MainActor.run {
                self.essaysByDate = essayDict
                self.keywordsByDate = keywordDict
            }
        } catch {
            print("Error loading essays: \(error)")
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let status: KeywordArchiveView.DayStatus?
    let isSelected: Bool
    let isToday: Bool
    
    private let indigoColor = Color(hex: "0D244D")
    private let mossColor = Color(hex: "4A5A30")
    private let rubyColor = Color(hex: "852E47")
    private let burntColor = Color(hex: "C2441C")
    private let creamColor = Color(hex: "F5F0E8")
    
    var body: some View {
        VStack(spacing: 6) {
            // Colored circle - no date number, just color
            ZStack {
                // Background circle - colored based on status
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: 36, height: 36)
                
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(indigoColor, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                // Today ring (if not selected)
                if isToday && !isSelected {
                    Circle()
                        .stroke(indigoColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 38, height: 38)
                }
            }
        }
        .frame(height: 50)
    }
    
    private var circleBackgroundColor: Color {
        guard let status = status else { return creamColor }
        
        switch status {
        case .written:
            return mossColor
        case .todayEmpty:
            return isSelected ? indigoColor : creamColor
        case .missed:
            return rubyColor
        case .future:
            return burntColor.opacity(0.3)
        }
    }
}

// MARK: - Archive Essay Card
struct ArchiveEssayCard: View {
    let essay: Essay
    private let indigoColor = Color(hex: "0D244D")
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(indigoColor.opacity(0.08))
                    .frame(width: 48, height: 48)
                
                Text(KeywordEmojiService.shared.emojiForKeyword(essay.keyword))
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(indigoColor)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(essay.wordCount) words".localized)
                        .font(.system(size: 12))
                        .foregroundStyle(indigoColor.opacity(0.5))
                    
                    if essay.visibility == .public {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                            Text("\(essay.likesCount)")
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(indigoColor.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(indigoColor.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(indigoColor.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(indigoColor.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    KeywordArchiveView()
}
