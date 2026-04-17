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
    @StateObject private var themeManager = ThemeManager.shared
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
                    .foregroundStyle(themeManager.accent)
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
                    .foregroundStyle(themeManager.accent)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 10) {
            // Weekday headers
            HStack {
                ForEach(Array(calendar.shortWeekdaySymbols.enumerated()), id: \.offset) { index, day in
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
                        .foregroundStyle(themeManager.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(themeManager.accent.opacity(0.1))
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
                                .foregroundStyle(themeManager.accent)
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
    @StateObject private var themeManager = ThemeManager.shared
    
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
                        .fill(themeManager.accent)
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
                .stroke(isSelected ? themeManager.accent : Color.clear, lineWidth: 2)
        )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return themeManager.accent.opacity(0.15)
        } else if isToday {
            return themeManager.accent.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return themeManager.accent
        } else if isToday {
            return themeManager.accent
        } else {
            return .primary
        }
    }
}

// MARK: - Archive Essay Card
struct ArchiveEssayCard: View {
    let essay: Essay
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Keyword badge with emoji
            let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
            Text(emoji)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.accent.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Content preview with Markdown support
                if let attributedPreview = try? AttributedString(
                    markdown: String(essay.content.prefix(100)),
                    options: AttributedString.MarkdownParsingOptions(
                        interpretedSyntax: .inlineOnlyPreservingWhitespace
                    )
                ) {
                    Text(attributedPreview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text(essay.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    Label("\(essay.likesCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Label("\(essay.commentsCount)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundStyle(themeManager.accent)
                    
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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var visibility: EssayVisibility
    @State private var isUpdating = false
    @State private var showingEditSheet = false
    @State private var showingVisibilityPicker = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var isLiked = false
    @State private var likeCount: Int
    @Environment(\.dismiss) private var dismiss
    
    init(essay: Essay) {
        self.essay = essay
        _visibility = State(initialValue: essay.visibility)
        _likeCount = State(initialValue: essay.likesCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(essay.keyword)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(themeManager.accent.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Title with saved font or default
                    if let fontName = essay.fontName, let appFont = AppFont(rawValue: fontName) {
                        Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                            .font(appFont.font(size: (essay.fontSize.map { CGFloat($0) } ?? 17) + 6))
                            .fontWeight(.bold)
                    } else {
                        Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                            .font(.title.bold())
                    }
                    
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
                            .foregroundStyle(themeManager.accent)
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
                
                // Content with saved font and line spacing on paper background
                ZStack {
                    PaperBackgroundView()
                    
                    // Try to display attributed content first
                    if let attributedStringBase64 = essay.attributedContentData,
                       let attributedData = Data(base64Encoded: attributedStringBase64),
                       let nsAttributedString = try? NSAttributedString(data: attributedData, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil) {
                        // Re-apply the correct font from essay settings
                        let mutableAttrString = NSMutableAttributedString(attributedString: nsAttributedString)
                        let fullRange = NSRange(location: 0, length: mutableAttrString.length)
                        let _ = {
                            if fullRange.length > 0,
                               let fontName = essay.fontName,
                               let appFont = AppFont(rawValue: fontName) {
                                // Get the correct UIFont using FontManager's updated PostScript names
                                let uiFont = appFont.uiFont(size: CGFloat(essay.fontSize ?? 16))
                                mutableAttrString.addAttribute(.font, value: uiFont, range: fullRange)
                            }
                        }()
                        AttributedTextView(attributedString: mutableAttrString)
                            .padding(24)
                    } else if let attributedContent = try? AttributedString(
                        markdown: essay.content,
                        options: AttributedString.MarkdownParsingOptions(
                            interpretedSyntax: .inlineOnlyPreservingWhitespace
                        )
                    ) {
                        Text(attributedContent)
                            .font(essayFont())
                            .lineSpacing(essayLineSpacing())
                            .padding(24)
                    } else {
                        Text(essay.content)
                            .font(essayFont())
                            .lineSpacing(essayLineSpacing())
                            .padding(24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Like and Comment buttons
                HStack(spacing: 20) {
                    Button {
                        toggleLike()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                            Text("\(likeCount)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(isLiked ? .red : .secondary)
                    }
                    
                    // Comment count label (comments shown inline below)
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(essay.commentsCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Comments Section - only show if essay has an ID
                if let essayId = essay.id {
                    ThreadedCommentsSectionView(essayId: essayId)
                }
            }
            .padding()
        }
        .toolbar {
            if essay.authorId == Auth.auth().currentUser?.uid {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Edit button (only for author)
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit".localized, systemImage: "pencil")
                        }
                        
                        // Delete button (only for author)
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete".localized, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Move to Recently Deleted?".localized, isPresented: $showingDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Move".localized, role: .destructive) {
                Task {
                    await deleteEssay()
                }
            }
        } message: {
            Text("This essay will be moved to Recently Deleted and permanently deleted after 30 days.".localized)
        }
        .overlay {
            if isUpdating || isDeleting {
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
    
    private func toggleLike() {
        print("[DEBUG] toggleLike called - isLiked: \(isLiked), essayId: \(essay.id ?? "nil")")
        Task {
            do {
                if isLiked {
                    try await FirebaseService.shared.unlikeEssay(essayId: essay.id!)
                    await MainActor.run {
                        isLiked = false
                        likeCount -= 1
                        print("[DEBUG] Unliked - new count: \(likeCount)")
                    }
                } else {
                    try await FirebaseService.shared.likeEssay(essayId: essay.id!)
                    await MainActor.run {
                        isLiked = true
                        likeCount += 1
                        print("[DEBUG] Liked - new count: \(likeCount)")
                    }
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    private func deleteEssay() async {
        guard let essayId = essay.id, !essayId.isEmpty else {
            print("❌ Error: Essay ID is nil or empty")
            return
        }
        print("🗑️ Soft deleting essay: \(essayId)")
        isDeleting = true
        do {
            try await FirebaseService.shared.softDeleteEssay(essayId: essayId)
            print("✅ Essay soft deleted successfully")
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Error deleting essay: \(error)")
        }
        isDeleting = false
    }
    
    private func updateVisibility(_ newVisibility: EssayVisibility) async {
        guard let essayId = essay.id, !essayId.isEmpty else {
            print("Error: Essay ID is nil")
            return
        }
        isUpdating = true
        do {
            try await FirebaseService.shared.updateEssayVisibility(essayId: essayId, visibility: newVisibility)
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
    
    // Helper to get the font from essay's saved font name
    private func essayFont() -> Font {
        guard let fontName = essay.fontName,
              let appFont = AppFont(rawValue: fontName) else {
            return .body
        }
        let size = CGFloat(essay.fontSize ?? 16)
        return appFont.font(size: size)
    }
    
    // Helper to get the line spacing from essay
    private func essayLineSpacing() -> CGFloat {
        return CGFloat(essay.lineSpacing ?? 6) // Default to 6 if not set
    }
}

// MARK: - Comments Section View (Inline)

struct CommentsSectionView: View {
    let essayId: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var comments: [Comment] = []
    @State private var authorProfiles: [String: UserProfile] = [:]
    @State private var newComment = ""
    @State private var isLoading = false
    @State private var replyingTo: Comment? = nil  // Track which comment we're replying to
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Comments".localized)
                    .font(.headline)
                
                if comments.count > 0 {
                    Text("\(comments.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.accent)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // Sort dropdown
                Menu {
                    Button("Most Recent".localized) { }
                } label: {
                    HStack(spacing: 4) {
                        Text("Most Recent".localized)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No comments yet. Be the first!".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Comments List
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(comments) { comment in
                        CommentRow(
                            comment: comment,
                            authorProfile: authorProfiles[comment.authorId],
                            onDelete: { deleteComment(comment) },
                            onLike: { toggleCommentLike(comment) },
                            onReply: { startReply(to: comment) }
                        )
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            
            // Reply indicator
            if let replyingTo = replyingTo {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.up.left")
                        .font(.caption)
                        .foregroundStyle(themeManager.accent)
                    
                    Text("Replying to".localized + " \(replyingTo.authorName)...")
                        .font(.caption)
                        .foregroundStyle(themeManager.accent)
                    
                    Spacer()
                    
                    Button {
                        self.replyingTo = nil
                        newComment = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(themeManager.accent.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Add Comment
            HStack(spacing: 12) {
                // Current user avatar
                AvatarView(url: nil, size: 32, userId: Auth.auth().currentUser?.uid ?? "")
                
                TextField(replyingTo == nil ? "Share your mind...".localized : "Write a reply...".localized, text: $newComment)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button {
                    postComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(newComment.isEmpty ? .secondary : themeManager.accent)
                }
                .disabled(newComment.isEmpty)
            }
            .padding(.top, 8)
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        isLoading = true
        do {
            comments = try await FirebaseService.shared.getComments(for: essayId)
            
            // Fetch author profiles for all comments
            var uniqueAuthorIds = Set(comments.map { $0.authorId })
            if let currentUserId = Auth.auth().currentUser?.uid {
                uniqueAuthorIds.insert(currentUserId)
            }
            
            for authorId in uniqueAuthorIds {
                if let profile = try? await FirebaseService.shared.getUserProfile(userId: authorId) {
                    await MainActor.run {
                        authorProfiles[authorId] = profile
                    }
                }
            }
        } catch {
            print("Error loading comments: \(error)")
        }
        isLoading = false
    }
    
    private func startReply(to comment: Comment) {
        replyingTo = comment
        newComment = "@\(comment.authorName) "
    }
    
    private func postComment() {
        guard !newComment.isEmpty else { return }
        
        Task {
            do {
                let parentId = replyingTo?.id
                try await FirebaseService.shared.addComment(essayId: essayId, content: newComment, parentCommentId: parentId)
                newComment = ""
                replyingTo = nil
                await loadComments()
            } catch {
                print("Error posting comment: \(error)")
            }
        }
    }
    
    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await FirebaseService.shared.deleteComment(commentId: comment.id ?? "", essayId: essayId)
                await loadComments()
            } catch {
                print("Error deleting comment: \(error)")
            }
        }
    }
    
    private func toggleCommentLike(_ comment: Comment) {
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else { return }
                let isLiked = comment.likedBy?.contains(currentUserId) ?? false
                
                if isLiked {
                    try await FirebaseService.shared.unlikeComment(commentId: comment.id ?? "")
                } else {
                    try await FirebaseService.shared.likeComment(commentId: comment.id ?? "")
                }
                await loadComments()
            } catch {
                print("Error toggling comment like: \(error)")
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let authorProfile: UserProfile?
    let onDelete: (() -> Void)?
    let onLike: (() -> Void)?
    let onReply: (() -> Void)?
    @State private var showingDeleteAlert = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            AvatarView(url: authorProfile?.profilePhotoUrl, size: 36, userId: comment.authorId)
            
            VStack(alignment: .leading, spacing: 6) {
                // Author name and time
                HStack(spacing: 8) {
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(timeAgo(from: comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Delete button (only for comment author)
                    if canDeleteComment {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Comment content
                Text(comment.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                // Like and Reply buttons
                HStack(spacing: 16) {
                    Button {
                        onLike?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.caption)
                            Text("\(comment.likesCount ?? 0)")
                                .font(.caption)
                        }
                        .foregroundStyle(isLiked ? themeManager.accent : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onReply?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.caption)
                            if let replyCount = comment.repliesCount, replyCount > 0 {
                                Text("\(replyCount)")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .alert("Delete Comment?".localized, isPresented: $showingDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This cannot be undone.".localized)
        }
    }
    
    private var canDeleteComment: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return comment.authorId == currentUserId
    }
    
    private var isLiked: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return comment.likedBy?.contains(currentUserId) ?? false
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Attributed Text View for displaying rich text

struct AttributedTextView: UIViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.attributedText = attributedString
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}

#Preview {
    KeywordArchiveView()
}
