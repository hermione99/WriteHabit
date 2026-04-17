import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TopicGroup: Identifiable {
    let id = UUID()
    let keyword: String
    let essays: [Essay]
    var essayCount: Int { essays.count }
    let customEmoji: String?
    
    init(keyword: String, essays: [Essay], emoji: String? = nil) {
        self.keyword = keyword
        self.essays = essays
        self.customEmoji = emoji
    }
    
    var emoji: String {
        if let custom = customEmoji {
            return custom
        }
        return KeywordEmojiService.shared.emojiForKeyword(keyword)
    }
}

struct EssayItem: Identifiable {
    let id: String
    let essay: Essay
    let author: UserProfile?
    
    init(essay: Essay, author: UserProfile?) {
        self.essay = essay
        self.author = author
        // Use essay ID if available, otherwise generate a stable ID
        self.id = essay.id ?? UUID().uuidString
    }
}

struct FeedView: View {
    @Binding var navigateToEssayId: String?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedFilter = 0
    @State private var essayItems: [EssayItem] = []
    @State private var isLoading = false
    
    // Sort options
    @State private var followingSort: FollowingSort = .all
    @State private var recentSort: RecentSort = .date
    @State private var topicSort: TopicSort = .keyword
    
    // By Topic specific
    @State private var topicGroups: [TopicGroup] = []
    @State private var selectedTopic: TopicGroup?
    
    // For notification navigation
    @State private var selectedEssayForDetail: Essay? = nil
    @State private var selectedAuthorForDetail: UserProfile? = nil
    @State private var showEssayDetail = false
    
    let filters = ["Following".localized, "Today".localized, "Recent".localized, "By Topic".localized]
    
    enum FollowingSort: String, CaseIterable {
        case all = "All"
        case friendsOnly = "Friends Only"
    }
    
    enum RecentSort: String, CaseIterable {
        case date = "Date"
        case likes = "Likes"
        case trending = "Trending"
    }
    
    enum TopicSort: String, CaseIterable {
        case keyword = "Keyword"
        case date = "Date"
        case popular = "Popular"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter".localized, selection: $selectedFilter) {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Text(filters[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedFilter) { _ in
                    selectedTopic = nil // Reset topic view when switching filters
                    Task {
                        await loadEssays()
                    }
                }
                
                // Sort controls for Following and Recent tabs
                if selectedFilter == 0 || selectedFilter == 2 {
                    HStack {
                        Spacer()
                        Menu {
                            if selectedFilter == 0 {
                                // Following sort options
                                Button {
                                    followingSort = .all
                                    Task { await loadEssays() }
                                } label: {
                                    Label("All", systemImage: followingSort == .all ? "checkmark" : "")
                                }
                                Button {
                                    followingSort = .friendsOnly
                                    Task { await loadEssays() }
                                } label: {
                                    Label("Friends Only", systemImage: followingSort == .friendsOnly ? "checkmark" : "")
                                }
                            } else {
                                // Recent sort options
                                Button {
                                    recentSort = .date
                                    Task { await loadEssays() }
                                } label: {
                                    Label("Date", systemImage: recentSort == .date ? "checkmark" : "")
                                }
                                Button {
                                    recentSort = .likes
                                    Task { await loadEssays() }
                                } label: {
                                    Label("Likes", systemImage: recentSort == .likes ? "checkmark" : "")
                                }
                                Button {
                                    recentSort = .trending
                                    Task { await loadEssays() }
                                } label: {
                                    Label("Trending", systemImage: recentSort == .trending ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(selectedFilter == 0 ? followingSort.rawValue : recentSort.rawValue)
                                    .font(.caption)
                            }
                            .foregroundStyle(themeManager.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeManager.accent.opacity(0.1))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                
                // Feed content
                if isLoading {
                    ProgressView()
                        .padding()
                } else if selectedFilter == 3 {
                    // By Topic view - show topic cards or selected topic essays
                    if let selectedTopic = selectedTopic {
                        // Show essays for selected topic
                        TopicDetailView(topic: selectedTopic, onBack: { self.selectedTopic = nil })
                    } else if topicGroups.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No past topics yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Check back tomorrow for your first topic archive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Show topic cards grid
                        TopicCardsView(topics: topicGroups, sort: $topicSort, onSelect: { topic in
                            self.selectedTopic = topic
                        })
                    }
                } else {
                    List {
                        ForEach(essayItems) { item in
                            EssayCard(essay: item.essay, author: item.author)
                                .id(item.id) // Use stable ID from EssayItem
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .buttonStyle(.borderless) // Prevent list selection from interfering
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadEssays()
                    }
                    // High priority gesture for filter switching
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .local)
                            .onEnded { value in
                                // Only handle horizontal swipes
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                
                                let threshold: CGFloat = 80
                                if value.translation.width < -threshold {
                                    // Swipe left - next filter
                                    if selectedFilter < filters.count - 1 {
                                        withAnimation(.easeInOut) {
                                            selectedTopic = nil
                                            selectedFilter += 1
                                            Task { await loadEssays() }
                                        }
                                    }
                                } else if value.translation.width > threshold {
                                    // Swipe right - previous filter
                                    if selectedFilter > 0 {
                                        withAnimation(.easeInOut) {
                                            selectedTopic = nil
                                            selectedFilter -= 1
                                            Task { await loadEssays() }
                                        }
                                    }
                                }
                            }
                    )
                }
            }
            .navigationTitle("Feed".localized)
        }
        .task {
            await loadEssays()
        }
        .sheet(isPresented: $showEssayDetail) {
            NavigationStack {
                if let essay = selectedEssayForDetail {
                    EssayDetailView(essay: essay)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done".localized) {
                                    showEssayDetail = false
                                }
                            }
                        }
                }
            }
        }
        .onChange(of: navigateToEssayId) { _, newEssayId in
            if let essayId = newEssayId {
                Task {
                    await navigateToEssay(essayId: essayId)
                    navigateToEssayId = nil // Reset after handling
                }
            }
        }
    }
    
    private func navigateToEssay(essayId: String) async {
        // Check if essay is already in the list
        if let existingItem = essayItems.first(where: { $0.essay.id == essayId }) {
            selectedEssayForDetail = existingItem.essay
            selectedAuthorForDetail = existingItem.author
            showEssayDetail = true
        } else {
            // Fetch the essay
            do {
                if let essay = try await FirebaseService.shared.getEssay(id: essayId) {
                    let author = try? await FirebaseService.shared.getUserProfile(userId: essay.authorId)
                    await MainActor.run {
                        selectedEssayForDetail = essay
                        selectedAuthorForDetail = author
                        showEssayDetail = true
                    }
                }
            } catch {
                print("Error fetching essay: \(error)")
            }
        }
    }
    
    private func loadEssays() async {
        isLoading = true
        do {
            var loadedEssays: [Essay] = []
            let currentUserId = Auth.auth().currentUser?.uid
            
            switch selectedFilter {
            case 0: // Following with sort
                if let userId = currentUserId {
                    var followingEssays = try await FirebaseService.shared.getFollowingEssays(userId: userId)
                    let myEssays = try await FirebaseService.shared.getUserEssays(userId: userId)
                    var combined = followingEssays + myEssays
                    
                    // Remove duplicates
                    var seenIds = Set<String>()
                    combined = combined.filter { essay in
                        guard let id = essay.id else { return false }
                        if seenIds.contains(id) { return false }
                        seenIds.insert(id)
                        return true
                    }
                    
                    // Apply Friends Only filter if selected
                    if followingSort == .friendsOnly {
                        let profile = try await FirebaseService.shared.getUserProfile(userId: userId)
                        let friendIds = Set(profile?.friends ?? [])
                        combined = combined.filter { friendIds.contains($0.authorId) }
                    }
                    
                    loadedEssays = combined.sorted { $0.createdAt > $1.createdAt }.prefix(50).map { $0 }
                }
            case 1: // Today - today's keyword essays only
                if let userId = currentUserId {
                    let allEssays = try await FirebaseService.shared.getDailyEssays(userId: userId, limit: 50)
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    loadedEssays = allEssays.filter { $0.createdAt >= today && $0.createdAt < tomorrow }
                        .sorted { $0.createdAt > $1.createdAt }
                }
            case 2: // Recent with sort
                if let userId = currentUserId {
                    var allEssays = try await FirebaseService.shared.getDailyEssays(userId: userId, limit: 100)
                    switch recentSort {
                    case .date:
                        loadedEssays = allEssays.sorted { $0.createdAt > $1.createdAt }
                    case .likes:
                        loadedEssays = allEssays.sorted { $0.likesCount > $1.likesCount }
                    case .trending:
                        // Trending = combination of recent + likes
                        loadedEssays = allEssays.sorted {
                            let score1 = $0.likesCount + Int($0.commentsCount)
                            let score2 = $1.likesCount + Int($1.commentsCount)
                            return score1 > score2
                        }
                    }
                }
            case 3: // By Topic - past keywords
                topicGroups = try await getTopicGroups()
            default:
                if let userId = currentUserId {
                    loadedEssays = try await FirebaseService.shared.getDailyEssays(userId: userId, limit: 50)
                } else {
                    loadedEssays = try await FirebaseService.shared.getDailyEssays(limit: 50)
                }
            }
            
            // Fetch author profiles for all essays
            essayItems = await enrichWithAuthors(essays: loadedEssays)
            
        } catch {
            print("Error loading essays: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func getTopicGroups() async throws -> [TopicGroup] {
        // Get all past keywords from archive
        let pastKeywords = try await KeywordsService.shared.getPastKeywords()
        print("DEBUG: Found \(pastKeywords.count) past keywords in archive")
        
        // Get essay counts for each keyword
        var topicGroups: [TopicGroup] = []
        
        for keywordArchive in pastKeywords {
            // Get essays for this keyword
            let essays = try await getEssaysForKeyword(keywordArchive.keyword)
            
            let topicGroup = TopicGroup(
                keyword: keywordArchive.keyword,
                essays: essays,
                emoji: keywordArchive.emoji
            )
            topicGroups.append(topicGroup)
        }
        
        print("DEBUG: Created \(topicGroups.count) topic groups")
        return topicGroups
    }
    
    private func getEssaysForKeyword(_ keyword: String) async throws -> [Essay] {
        let db = FirebaseFirestore.Firestore.firestore()
        let snapshot = try await db.collection("essays")
            .whereField("keyword", isEqualTo: keyword)
            .whereField("isDraft", isEqualTo: false)
            .whereField("visibility", isEqualTo: "public") // Only public essays
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            do {
                var essay = try doc.data(as: Essay.self)
                if essay.id == nil {
                    essay.id = doc.documentID
                }
                return essay
            } catch {
                return nil
            }
        }
    }
    
    private func enrichWithAuthors(essays: [Essay]) async -> [EssayItem] {
        // Get unique author IDs
        let authorIds = Set(essays.map { $0.authorId })
        
        // Fetch all author profiles
        var authors: [String: UserProfile] = [:]
        await withTaskGroup(of: (String, UserProfile?).self) { group in
            for authorId in authorIds {
                group.addTask {
                    do {
                        let profile = try await FirebaseService.shared.getUserProfile(userId: authorId)
                        return (authorId, profile)
                    } catch {
                        return (authorId, nil)
                    }
                }
            }
            
            for await (authorId, profile) in group {
                if let profile = profile {
                    authors[authorId] = profile
                }
            }
        }
        
        return essays.map { essay in
            EssayItem(essay: essay, author: authors[essay.authorId])
        }
    }
}

struct EssayCard: View {
    let essay: Essay
    let author: UserProfile?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var showingDetail = false
    @State private var showingAuthorProfile = false
    
    init(essay: Essay, author: UserProfile?) {
        self.essay = essay
        self.author = author
        _likeCount = State(initialValue: essay.likesCount)
    }
    
    var displayName: String {
        author?.displayName ?? essay.authorName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author header (tappable to view profile)
            Button {
                showingAuthorProfile = true
            } label: {
                HStack {
                    // Author avatar
                    if let author = author {
                        AvatarView(url: author.profilePhotoUrl, size: 40, userId: author.userId)
                    } else {
                        Circle()
                            .fill(themeManager.accent.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(themeManager.accent)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(timeAgo(from: essay.createdAt)) · \("Prompt".localized): \(essay.keyword)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Visibility icon
                    Image(systemName: essay.visibility.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingAuthorProfile) {
                NavigationStack {
                    ProfileView(userId: essay.authorId, onSignOut: nil)
                }
            }
            
            // Essay preview (tappable to view full) - isolated from interaction bar
            Button {
                showingDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    // Keyword badge with emoji
                    HStack {
                        let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
                        Text("\(emoji) \(essay.keyword.isEmpty ? "No keyword" : essay.keyword)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorForKeyword(essay.keyword))
                            )
                        Spacer()
                    }
                    
                    if !essay.title.isEmpty {
                        Text(essay.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(essay.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 12) // Increased vertical padding for larger tap area
                .frame(maxWidth: .infinity, alignment: .leading) // Full width
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            
            // Spacer to ensure separation from interaction bar
            Spacer()
                .frame(height: 4)
            
            // Interaction bar - completely isolated from above content
            HStack(spacing: 20) {
                // Like button - isolated with explicit hit testing
                Button {
                    print("[DEBUG] Like button tapped - essayId: \(essay.id ?? "nil")")
                    toggleLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .frame(width: 20, height: 20)
                        Text("\(likeCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(isLiked ? .red : .secondary)
                    .contentShape(Rectangle())
                    .background(Color.clear) // Force clear background
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44) // Minimum tappable area
                
                // Comment button - isolated
                Button {
                    print("[DEBUG] Comment button tapped")
                    showingDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .frame(width: 20, height: 20)
                        Text("\(essay.commentsCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .background(Color.clear)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                
                Spacer()
            }
            // Explicitly disable gesture propagation
            .simultaneousGesture(TapGesture(), including: .none)
            .background(Color.clear)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
        .onAppear {
            // Update state when view appears
            likeCount = essay.likesCount
            isLiked = false // Reset like state
        }
        .onChange(of: essay.id) { _ in
            // Update state when essay changes
            likeCount = essay.likesCount
            isLiked = false
        }
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                EssayDetailView(essay: essay)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done".localized) {
                                showingDetail = false
                            }
                        }
                    }
            }
        }
    }
    
    private func toggleLike() {
        Task {
            do {
                if isLiked {
                    try await FirebaseService.shared.unlikeEssay(essayId: essay.id ?? "")
                    await MainActor.run {
                        isLiked = false
                        likeCount -= 1
                    }
                } else {
                    try await FirebaseService.shared.likeEssay(essayId: essay.id ?? "")
                    await MainActor.run {
                        isLiked = true
                        likeCount += 1
                    }
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Generate consistent color for each keyword
    private func colorForKeyword(_ keyword: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .pink, .purple, .teal, .indigo, .cyan, .mint, .red
        ]
        
        // Use hash of keyword to pick consistent color
        var hash = 0
        for char in keyword.unicodeScalars {
            hash = Int(char.value) + (hash << 6) + (hash << 16) - hash
        }
        
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

struct CommentsView: View {
    let essayId: String
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                List(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.authorName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(comment.content)
                            .font(.body)
                        Text(timeAgo(from: comment.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                HStack {
                    TextField("Add a comment...".localized, text: $newComment)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Post".localized) {
                        postComment()
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        do {
            comments = try await FirebaseService.shared.getComments(for: essayId)
        } catch {
            print("Error loading comments: \(error)")
        }
    }
    
    private func postComment() {
        Task {
            do {
                try await FirebaseService.shared.addComment(essayId: essayId, content: newComment)
                newComment = ""
                await loadComments()
            } catch {
                print("Error posting comment: \(error)")
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Topic Cards View

struct TopicCardsView: View {
    let topics: [TopicGroup]
    @Binding var sort: FeedView.TopicSort
    let onSelect: (TopicGroup) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var sortedTopics: [TopicGroup] {
        switch sort {
        case .keyword:
            return topics.sorted { $0.keyword < $1.keyword }
        case .date:
            return topics.sorted {
                guard let d1 = $0.essays.first?.createdAt,
                      let d2 = $1.essays.first?.createdAt else { return false }
                return d1 > d2
            }
        case .popular:
            return topics.sorted { $0.essayCount > $1.essayCount }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Sort picker
                HStack {
                    Spacer()
                    Menu {
                        Button {
                            sort = .keyword
                        } label: {
                            Label("Keyword", systemImage: sort == .keyword ? "checkmark" : "")
                        }
                        Button {
                            sort = .date
                        } label: {
                            Label("Date", systemImage: sort == .date ? "checkmark" : "")
                        }
                        Button {
                            sort = .popular
                        } label: {
                            Label("Popular", systemImage: sort == .popular ? "checkmark" : "")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sort.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(themeManager.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.accent.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Topic cards grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                    ForEach(sortedTopics) { topic in
                        TopicCard(topic: topic)
                            .onTapGesture {
                                onSelect(topic)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Topic Card

struct TopicCard: View {
    let topic: TopicGroup
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Text(topic.emoji)
                .font(.system(size: 40))
            
            Text(topic.keyword)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(topic.essayCount) essays")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 140, minHeight: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Topic Detail View

struct TopicDetailView: View {
    let topic: TopicGroup
    let onBack: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingWriteSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with back button and write button
                HStack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back".localized)
                        }
                    }
                    .foregroundStyle(themeManager.accent)
                    
                    Spacer()
                    
                    // Write on past topic button
                    Button {
                        showingWriteSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Write".localized)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.accent)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                // Topic header
                VStack(spacing: 8) {
                    Text(topic.emoji)
                        .font(.system(size: 60))
                    Text(topic.keyword)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(topic.essayCount) essays")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Divider()
                    .padding(.horizontal)
                
                // Essays list
                LazyVStack(spacing: 12) {
                    ForEach(topic.essays, id: \.id) { essay in
                        TopicEssayRow(essay: essay)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingWriteSheet) {
            // Open writing editor with past keyword
            SimpleWritingEditorView(keyword: topic.keyword, isPastTopic: true)
        }
    }
}

// MARK: - Topic Essay Row

struct TopicEssayRow: View {
    let essay: Essay
    @StateObject private var themeManager = ThemeManager.shared
    @State private var authorName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(timeAgo(from: essay.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(essay.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("\(essay.likesCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.leading, 8)
                Text("\(essay.commentsCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    FeedView(navigateToEssayId: .constant(nil))
}
