import SwiftUI
import FirebaseAuth

struct EssayItem: Identifiable {
    let id = UUID()
    let essay: Essay
    let author: UserProfile?
}

struct FeedView: View {
    @State private var selectedFilter = 0
    @State private var essayItems: [EssayItem] = []
    @State private var isLoading = false
    let filters = ["Following".localized, "Discover".localized, "Recent".localized, "Friends".localized, "Trending".localized]
    
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
                    Task {
                        await loadEssays()
                    }
                }
                
                // Feed content
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    List {
                        ForEach(essayItems) { item in
                            EssayCard(essay: item.essay, author: item.author)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
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
    }
    
    private func loadEssays() async {
        isLoading = true
        do {
            var loadedEssays: [Essay] = []
            
            switch selectedFilter {
            case 0: // Following
                if let userId = Auth.auth().currentUser?.uid {
                    var followingEssays = try await FirebaseService.shared.getFollowingEssays(userId: userId)
                    let myEssays = try await FirebaseService.shared.getUserEssays(userId: userId)
                    // Add your own essays to the Following feed
                    var combined = followingEssays + myEssays
                    // Remove duplicates if any
                    var seenIds = Set<String>()
                    combined = combined.filter { essay in
                        guard let id = essay.id else { return false }
                        if seenIds.contains(id) {
                            return false
                        }
                        seenIds.insert(id)
                        return true
                    }
                    loadedEssays = combined.sorted { $0.createdAt > $1.createdAt }.prefix(50).map { $0 }
                }
            case 1: // Discover - today's essays
                let allEssays = try await FirebaseService.shared.getDailyEssays()
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                loadedEssays = allEssays.filter { $0.createdAt >= today && $0.createdAt < tomorrow }.shuffled()
            case 2: // Recent
                loadedEssays = try await FirebaseService.shared.getDailyEssays(limit: 100)
            case 3: // Friends
                if let userId = Auth.auth().currentUser?.uid {
                    let profile = try await FirebaseService.shared.getUserProfile(userId: userId)
                    loadedEssays = try await FirebaseService.shared.getFriendsEssays(friendIds: profile?.friends ?? [])
                }
            case 4: // Trending
                let allEssays = try await FirebaseService.shared.getDailyEssays()
                loadedEssays = allEssays.sorted { $0.likesCount > $1.likesCount }
            default:
                loadedEssays = try await FirebaseService.shared.getDailyEssays()
            }
            
            // Fetch author profiles for all essays
            essayItems = await enrichWithAuthors(essays: loadedEssays)
            
        } catch {
            print("Error loading essays: \(error.localizedDescription)")
        }
        isLoading = false
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
    @State private var isLiked = false
    @State private var showingComments = false
    @State private var showingDetail = false
    @State private var showingAuthorProfile = false
    
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
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.blue)
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
                    ProfileView(userId: essay.authorId)
                }
            }
            
            // Essay preview (tappable to view full)
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
            }
            .buttonStyle(.plain)
            
            // Interaction bar
            HStack(spacing: 20) {
                Button {
                    toggleLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text("\(essay.likesCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(isLiked ? .red : .secondary)
                }
                
                Button {
                    showingComments = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(essay.commentsCount)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
        .sheet(isPresented: $showingComments) {
            CommentsView(essayId: essay.id ?? "")
        }
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                EssayDetailView(essay: essay)
                    .navigationTitle("Essay".localized)
                    .navigationBarTitleDisplayMode(.inline)
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
                } else {
                    try await FirebaseService.shared.likeEssay(essayId: essay.id ?? "")
                }
                await MainActor.run {
                    isLiked.toggle()
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

#Preview {
    FeedView()
}
