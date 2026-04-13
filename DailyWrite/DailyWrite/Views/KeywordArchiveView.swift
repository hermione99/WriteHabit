import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Import services for emoji badges
import Foundation

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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month navigation
                    monthHeader
                    
                    // Calendar grid
                    calendarGrid
                    
                    Divider()
                    
                    // Selected day detail
                    selectedDayDetail
                }
                .padding()
            }
            .navigationTitle("Writing Archive".localized)
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showingWritingView) {
                NavigationStack {
                    SimpleWritingEditorView(keyword: writingKeyword)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadEssaysForMonth()
        }
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonth))
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 10) {
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            keyword: keywordsByDate[dateFormatter.string(from: date)],
                            hasEssays: hasEssays(on: date),
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
    }
    
    // MARK: - Selected Day Detail
    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(formattedSelectedDate)
                    .font(.headline)
                
                Spacer()
                
                if let keyword = keywordForSelectedDate {
                    Text(keyword)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
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
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No essays on this day".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if calendar.isDateInToday(selectedDate) || selectedDate < Date() {
                        Button {
                            // Open writing view with this day's keyword
                            writingKeyword = keywordForSelectedDate ?? ""
                            showingWritingView = true
                        } label: {
                            Text("Write now".localized)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var keywordForSelectedDate: String? {
        keywordsByDate[dateFormatter.string(from: selectedDate)]
    }
    
    private var essaysForSelectedDate: [Essay]? {
        essaysByDate[dateFormatter.string(from: selectedDate)]
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Helper Methods
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let offsetDays = firstWeekday - 1 // Adjust for Sunday = 1
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Pad to complete the grid (6 rows * 7 days = 42)
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasEssays(on date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return essaysByDate[dateString]?.isEmpty == false
    }
    
    // MARK: - Data Loading
    private func loadEssaysForMonth() async {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        // Calculate date range for the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            isLoading = false
            return
        }
        
        do {
            // Fetch essays from Firebase for this date range
            let essays = try await FirebaseService.shared.getUserEssaysInDateRange(
                userId: user.uid,
                startDate: monthInterval.start,
                endDate: monthInterval.end
            )
            
            // Group by date
            var grouped: [String: [Essay]] = [:]
            for essay in essays {
                let dateKey = dateFormatter.string(from: essay.createdAt)
                if grouped[dateKey] == nil {
                    grouped[dateKey] = []
                }
                grouped[dateKey]?.append(essay)
            }
            
            await MainActor.run {
                self.essaysByDate = grouped
                self.loadKeywordsForMonth()
                self.isLoading = false
            }
        } catch {
            print("Error loading essays: \(error)")
            isLoading = false
        }
    }
    
    private func loadKeywordsForMonth() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }
        
        var currentDate = monthInterval.start
        var keywords: [String: String] = [:]
        
        while currentDate < monthInterval.end {
            let dateKey = dateFormatter.string(from: currentDate)
            // Use the keyword generator to get the keyword for this date
            Task {
                let keyword = await KeywordGenerator.shared.getDailyKeyword(language: languageManager.currentLanguage)
                keywords[dateKey] = keyword
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        self.keywordsByDate = keywords
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let keyword: String?
    let hasEssays: Bool
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            
            // Content
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(textColor)
                
                if hasEssays {
                    // Small indicator dot
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                } else if let keyword = keyword {
                    // Mini keyword preview
                    Text(keyword.prefix(2))
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .lineLimit(1)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.15)
        } else if isToday {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
}

// MARK: - Archive Essay Card
struct ArchiveEssayCard: View {
    let essay: Essay
    
    var body: some View {
        HStack(spacing: 12) {
            // Keyword badge with emoji
            let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
            Text(emoji)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(essay.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label("\(essay.likesCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Label("\(essay.commentsCount)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    if !essay.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Essay Detail View
struct EssayDetailView: View {
    let essay: Essay
    @State private var visibility: EssayVisibility
    @State private var isUpdating = false
    @State private var showingEditSheet = false
    @State private var showingVisibilityPicker = false
    
    init(essay: Essay) {
        self.essay = essay
        _visibility = State(initialValue: essay.visibility)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(essay.keyword)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                        .font(.title.bold())
                    
                    HStack {
                        Text(formattedDate(essay.createdAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // Visibility Picker
                        Button {
                            showingVisibilityPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: visibility.icon)
                                    .font(.caption)
                                Text(visibility.displayName.localized)
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                        .confirmationDialog("Select Visibility".localized, isPresented: $showingVisibilityPicker, titleVisibility: .visible) {
                            ForEach(EssayVisibility.allCases, id: \.self) { option in
                                Button(option.displayName.localized) {
                                    Task {
                                        await updateVisibility(option)
                                    }
                                }
                            }
                            Button("Cancel".localized, role: .cancel) { }
                        }
                    }
                }
                
                Divider()
                
                // Content
                Text(essay.content)
                    .font(.body)
                    .lineSpacing(6)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Essay".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit".localized) {
                    showingEditSheet = true
                }
            }
        }
        .overlay {
            if isUpdating {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .fullScreenCover(isPresented: $showingEditSheet) {
            NavigationStack {
                SimpleWritingEditorView(keyword: essay.keyword, existingEssay: essay, isDraft: false)
            }
        }
    }
    
    private func updateVisibility(_ newVisibility: EssayVisibility) async {
        isUpdating = true
        do {
            try await FirebaseService.shared.updateEssayVisibility(essayId: essay.id ?? "", visibility: newVisibility)
            visibility = newVisibility
        } catch {
            print("Error updating visibility: \(error)")
        }
        isUpdating = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    KeywordArchiveView()
}
