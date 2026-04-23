import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    
    // For notification navigation
    @State private var selectedEssayForDetail: Essay? = nil
    @State private var selectedAuthorForDetail: UserProfile? = nil
    @State private var showEssayDetail = false
    
    let filters = ["Following".localized, "Recent".localized]
    
    enum FollowingSort: String, CaseIterable {
        case all = "All"
        case friendsOnly = "Friends Only"
    }
    
    enum RecentSort: String, CaseIterable {
        case date = "Date"
        case likes = "Likes"
        case trending = "Trending"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beige background
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter picker
                    Picker("Filter".localized, selection: $selectedFilter) {
                        ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                            Text(filter).tag(index)
                        }
                    }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedFilter) { _ in
                    // Don't reload immediately, just switch the view
                    // Data will be refreshed in background or on pull-to-refresh
                    _Concurrency.Task {
                        await refreshIfNeeded()
                    }
                }
                
                // Sort controls for Following and Recent tabs
                if selectedFilter == 0 || selectedFilter == 1 {
                    HStack {
                        Spacer()
                        Menu {
                            if selectedFilter == 0 {
                                // Following sort options
                                Button {
                                    followingSort = .all
                                    _Concurrency.Task { await loadEssays() }
                                } label: {
                                    Label("All", systemImage: followingSort == .all ? "checkmark" : "")
                                }
                                Button {
                                    followingSort = .friendsOnly
                                    _Concurrency.Task { await loadEssays() }
                                } label: {
                                    Label("Friends Only", systemImage: followingSort == .friendsOnly ? "checkmark" : "")
                                }
                            } else {
                                // Recent sort options
                                Button {
                                    recentSort = .date
                                    _Concurrency.Task { await loadEssays() }
                                } label: {
                                    Label("Date", systemImage: recentSort == .date ? "checkmark" : "")
                                }
                                Button {
                                    recentSort = .likes
                                    _Concurrency.Task { await loadEssays() }
                                } label: {
                                    Label("Likes", systemImage: recentSort == .likes ? "checkmark" : "")
                                }
                                Button {
                                    recentSort = .trending
                                    _Concurrency.Task { await loadEssays() }
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
                
                // Feed content - Clean beige background with paper essay cards
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(essayItems) { item in
                                CleanPaperCard(
                                    essay: item.essay,
                                    author: item.author
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                    .refreshable {
                        await loadEssays()
                    }
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
                _Concurrency.Task {
                    await navigateToEssay(essayId: essayId)
                    navigateToEssayId = nil // Reset after handling
                }
            }
        }
    }
}

// MARK: - Helper Methods

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
                    
                    // Filter out deleted essays
                    combined = combined.filter { $0.deletedAt == nil }
                    
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
            case 1: // Recent with sort
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
    
    // Refresh data in background without clearing existing data
    private func refreshIfNeeded() async {
        // Skip if already loading
        if isLoading { return }
        
        do {
            var loadedEssays: [Essay] = []
            let currentUserId = Auth.auth().currentUser?.uid
            
            switch selectedFilter {
            case 0: // Following with sort
                if let userId = currentUserId {
                    var followingEssays = try await FirebaseService.shared.getFollowingEssays(userId: userId)
                    let myEssays = try await FirebaseService.shared.getUserEssays(userId: userId)
                    var combined = followingEssays + myEssays
                    
                    // Filter out deleted essays
                    combined = combined.filter { $0.deletedAt == nil }
                    
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
            case 1: // Recent with sort
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
            default:
                if let userId = currentUserId {
                    loadedEssays = try await FirebaseService.shared.getDailyEssays(userId: userId, limit: 50)
                } else {
                    loadedEssays = try await FirebaseService.shared.getDailyEssays(limit: 50)
                }
            }
            
            // Fetch author profiles for all essays
            let newItems = await enrichWithAuthors(essays: loadedEssays)
            
            // Only update if we got new data
            await MainActor.run {
                essayItems = newItems
            }
            
        } catch {
            print("Error refreshing essays: \(error.localizedDescription)")
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

// MARK: - Clean Paper Card
// Individual paper sheet card like the reference image
struct CleanPaperCard: View {
    let essay: Essay
    let author: UserProfile?
    
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var showingDetail = false
    @State private var selectedKeyword: String? = nil
    
    private let indigoColor = Color(hex: "0D244D")
    private let paperColor = Color(hex: "FDFBF7")
    
    init(essay: Essay, author: UserProfile?) {
        self.essay = essay
        self.author = author
        _likeCount = State(initialValue: essay.likesCount)
    }
    
    var displayName: String {
        author?.displayName ?? essay.authorName
    }
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            ZStack {
                // Clean paper background with subtle shadow
                Rectangle()
                    .fill(paperColor)
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 6,
                        x: 1,
                        y: 2
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Author row
                    HStack(spacing: 10) {
                        // Avatar
                        if let author = author, let photoUrl = author.profilePhotoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    Circle()
                                        .fill(indigoColor.opacity(0.08))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(indigoColor.opacity(0.4))
                                                .font(.system(size: 12))
                                        )
                                }
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(indigoColor.opacity(0.08))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(indigoColor.opacity(0.4))
                                        .font(.system(size: 12))
                                )
                        }
                        
                        Text(displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(indigoColor.opacity(0.8))
                        
                        Spacer()
                        
                        Text(timeAgo(from: essay.createdAt))
                            .font(.system(size: 11))
                            .foregroundStyle(indigoColor.opacity(0.35))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    
                    // Thin separator
                    Rectangle()
                        .fill(indigoColor.opacity(0.06))
                        .frame(height: 0.5)
                        .padding(.horizontal, 18)
                    
                    // Content area
                    VStack(alignment: .leading, spacing: 8) {
                        // Keyword - clickable badge
                        HStack {
                            Button {
                                selectedKeyword = essay.keyword
                            } label: {
                                let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
                                Text("\(emoji) \(essay.keyword)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(indigoColor.opacity(0.5))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        
                        // Navigation to KeywordBrowseView
                        .sheet(isPresented: Binding(
                            get: { selectedKeyword != nil },
                            set: { if !$0 { selectedKeyword = nil } }
                        )) {
                            if let keyword = selectedKeyword {
                                KeywordBrowseView(keyword: keyword)
                            }
                        }
                        
                        // Title
                        if !essay.title.isEmpty {
                            Text(essay.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(indigoColor)
                                .lineLimit(2)
                        }
                        
                        // Preview text
                        Text(essay.content)
                            .font(.system(size: 14))
                            .foregroundStyle(indigoColor.opacity(0.65))
                            .lineSpacing(3)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    
                    // Bottom stats row
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(isLiked ? Color(hex: "C2441C") : indigoColor.opacity(0.35))
                            Text("\(likeCount)")
                                .font(.system(size: 12))
                                .foregroundStyle(indigoColor.opacity(0.5))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 12))
                                .foregroundStyle(indigoColor.opacity(0.35))
                            Text("\(essay.commentsCount)")
                                .font(.system(size: 12))
                                .foregroundStyle(indigoColor.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: essay.visibility == .public ? "globe" : "lock")
                            .font(.system(size: 11))
                            .foregroundStyle(indigoColor.opacity(0.3))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            likeCount = essay.likesCount
            isLiked = false
        }
        .onChange(of: essay.id) { _ in
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
    
    private let indigoColor = Color(hex: "0D244D")
    private let creamColor = Color(hex: "F5F0E8")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beige background
                creamColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Comments list with paper texture
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Add a comment...".localized, text: $newComment)
                            .font(.system(size: 15))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: indigoColor.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        
                        Button {
                            postComment()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(newComment.isEmpty ? indigoColor.opacity(0.3) : indigoColor)
                        }
                        .disabled(newComment.isEmpty)
                    }
                    .padding()
                    .background(
                        Color.white
                            .shadow(color: indigoColor.opacity(0.05), radius: 8, x: 0, y: -4)
                    )
                }
            }
            .navigationTitle("Comments".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                    .foregroundStyle(indigoColor)
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
        _Concurrency.Task {
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

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    private let indigoColor = Color(hex: "0D244D")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author and time
            HStack {
                Text(comment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(indigoColor)
                
                Spacer()
                
                Text(timeAgo(from: comment.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(indigoColor.opacity(0.5))
            }
            
            // Comment content
            Text(comment.content)
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(indigoColor)
                .padding(.vertical, 4)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Paper Texture Background
struct PaperTextureBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base cream color
                Color(hex: "F5F0E8")
                
                // Paper texture overlay
                Canvas { context, size in
                    // Draw subtle noise texture
                    let rect = CGRect(origin: .zero, size: size)
                    
                    // Create a subtle grid pattern
                    let gridSpacing: CGFloat = 4
                    var path = Path()
                    
                    // Horizontal lines
                    for y in stride(from: 0, to: size.height, by: gridSpacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    
                    // Vertical lines
                    for x in stride(from: 0, to: size.width, by: gridSpacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(Color(hex: "E8E0D0").opacity(0.3)),
                        lineWidth: 0.5
                    )
                    
                    // Add some random speckles for paper texture
                    for _ in 0..<5000 {
                        let x = CGFloat.random(in: 0..<size.width)
                        let y = CGFloat.random(in: 0..<size.height)
                        let size = CGFloat.random(in: 0.5...1.5)
                        
                        let speckle = Path(ellipseIn: CGRect(
                            x: x,
                            y: y,
                            width: size,
                            height: size
                        ))
                        
                        context.fill(
                            speckle,
                            with: .color(Color(hex: "D4C8B8").opacity(0.2))
                        )
                    }
                }
                
                // Subtle vignette effect
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color(hex: "E8E0D0").opacity(0.1)
                    ],
                    center: .center,
                    startRadius: geometry.size.width * 0.3,
                    endRadius: geometry.size.width * 0.8
                )
                .blendMode(.multiply)
            }
        }
    }
}

#Preview {
    FeedView(navigateToEssayId: .constant(nil))
}
