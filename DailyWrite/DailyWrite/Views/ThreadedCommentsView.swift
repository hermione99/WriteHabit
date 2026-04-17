// MARK: - Threaded Comments Section View

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Helper struct for threaded comments
struct CommentNode: Identifiable {
    let comment: Comment
    var replies: [CommentNode]
    var isExpanded: Bool = true
    var parentAuthorName: String? // For replies, store the parent commenter's name
    
    var id: String { comment.id ?? UUID().uuidString }
}

struct ThreadedCommentsSectionView: View {
    let essayId: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var comments: [Comment] = []
    @State private var authorProfiles: [String: UserProfile] = [:]
    @State private var newComment = ""
    @State private var isLoading = false
    @State private var replyingTo: Comment? = nil
    @State private var expandedReplies: Set<String> = [] // Track which comments have expanded replies
    
    // Build thread tree from flat comments
    private var commentTree: [CommentNode] {
        let topLevel = comments.filter { $0.parentCommentId == nil }
        return topLevel.map { buildNode(for: $0) }
    }
    
    private func buildNode(for comment: Comment, parentAuthorName: String? = nil) -> CommentNode {
        let replies = comments.filter { $0.parentCommentId == comment.id }
        return CommentNode(
            comment: comment,
            replies: replies.map { buildNode(for: $0, parentAuthorName: comment.authorName) },
            isExpanded: expandedReplies.contains(comment.id ?? ""),
            parentAuthorName: parentAuthorName
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            headerView
            
            if isLoading {
                loadingView
            } else if comments.isEmpty {
                emptyView
            } else {
                // Threaded Comments List
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(commentTree) { node in
                        ThreadedCommentRow(
                            node: node,
                            authorProfile: authorProfiles[node.comment.authorId],
                            authorProfiles: authorProfiles,
                            level: 0,
                            expandedReplies: $expandedReplies,
                            onDelete: { deleteComment(node.comment) },
                            onLike: { toggleCommentLike(node.comment) },
                            onReply: { startReply(to: node.comment) }
                        )
                    }
                }
            }
            
            // Reply indicator
            replyIndicatorView
            
            // Add Comment
            addCommentView
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Comments".localized)
                .font(.headline)
            
            let topLevelCount = comments.filter { $0.parentCommentId == nil }.count
            if topLevelCount > 0 {
                Text("\(topLevelCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.accent)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }
    
    private var emptyView: some View {
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
    }
    
    private var replyIndicatorView: some View {
        Group {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.accent.opacity(0.1))
                .cornerRadius(8)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var addCommentView: some View {
        HStack(spacing: 12) {
            // Current user avatar
            if let currentUserId = Auth.auth().currentUser?.uid,
               let profile = authorProfiles[currentUserId] {
                AvatarView(url: profile.profilePhotoUrl, size: 36, userId: currentUserId)
            } else {
                AvatarView(url: nil, size: 36, userId: Auth.auth().currentUser?.uid ?? "")
            }
            
            HStack(spacing: 8) {
                TextField(replyingTo == nil ? "Share your mind...".localized : "Write a reply...".localized, 
                         text: $newComment)
                    .textFieldStyle(.plain)
                
                if !newComment.isEmpty {
                    Button {
                        postComment()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(themeManager.accent)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Functions
    
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
        // Auto-expand this comment's replies
        if let commentId = comment.id {
            expandedReplies.insert(commentId)
        }
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
                print("Error toggling like: \(error)")
            }
        }
    }
}

// MARK: - Threaded Comment Row

struct ThreadedCommentRow: View {
    let node: CommentNode
    let authorProfile: UserProfile?
    let authorProfiles: [String: UserProfile]  // Full dictionary for looking up reply authors
    let level: Int
    @Binding var expandedReplies: Set<String>
    let onDelete: () -> Void
    let onLike: () -> Void
    let onReply: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingOptions = false
    
    private let maxLevel = 3 // Max nesting depth
    private let indentWidth: CGFloat = 32
    
    private var isExpanded: Bool {
        expandedReplies.contains(node.comment.id ?? "")
    }
    
    private var hasReplies: Bool {
        !node.replies.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Comment content
            HStack(alignment: .top, spacing: 12) {
                // Indentation for replies
                if level > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<level, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 2)
                                .padding(.leading, indentWidth / 2)
                        }
                    }
                    .frame(width: CGFloat(level) * indentWidth)
                }
                
                // Avatar and content
                VStack(alignment: .leading, spacing: 8) {
                    // Header: Avatar + Name + Time
                    HStack(alignment: .center, spacing: 8) {
                        AvatarView(url: authorProfile?.profilePhotoUrl, size: 36, userId: node.comment.authorId)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authorProfile?.displayName ?? node.comment.authorName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(timeAgo(from: node.comment.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Options menu
                        Button {
                            showingOptions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                        .confirmationDialog("Comment Options", isPresented: $showingOptions, titleVisibility: .hidden) {
                            if node.comment.authorId == Auth.auth().currentUser?.uid {
                                Button("Delete".localized, role: .destructive) {
                                    onDelete()
                                }
                            }
                            Button("Cancel".localized, role: .cancel) { }
                        }
                    }
                    
                    // Comment text (strip @username prefix if it's a reply)
                    let displayContent = stripReplyMention(from: node.comment.content, parentAuthorName: node.parentAuthorName)
                    Text(displayContent)
                        .font(.subheadline)
                        .lineSpacing(2)
                    
                    // Actions bar
                    let isLiked = node.comment.likedBy?.contains(Auth.auth().currentUser?.uid ?? "") ?? false
                    HStack(spacing: 20) {
                        // Like button
                        Button {
                            onLike()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.caption)
                                Text("\(node.comment.likesCount ?? 0)")
                                    .font(.caption)
                            }
                            .foregroundStyle(isLiked ? themeManager.accent : .secondary)
                        }
                        
                        // Reply button
                        Button {
                            onReply()
                        } label: {
                            Text("Reply".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Show/hide replies button (if has replies)
                        if hasReplies {
                            Button {
                                toggleReplies()
                            } label: {
                                HStack(spacing: 4) {
                                    Text(isExpanded ? "Hide replies".localized : "Show replies".localized + " (\(node.replies.count))")
                                        .font(.caption)
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(themeManager.accent)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 12)
            
            // Replies (if expanded)
            if isExpanded && hasReplies && level < maxLevel {
                ForEach(node.replies) { replyNode in
                    ThreadedCommentRow(
                        node: replyNode,
                        authorProfile: authorProfiles[replyNode.comment.authorId],
                        authorProfiles: authorProfiles,
                        level: level + 1,
                        expandedReplies: $expandedReplies,
                        onDelete: onDelete,
                        onLike: onLike,
                        onReply: onReply
                    )
                }
            }
            
            // Divider (except for last item)
            if level == 0 {
                Divider()
                    .padding(.leading, hasReplies && isExpanded ? 0 : 48)
            }
        }
    }
    
    private func toggleReplies() {
        guard let commentId = node.comment.id else { return }
        if isExpanded {
            expandedReplies.remove(commentId)
        } else {
            expandedReplies.insert(commentId)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Strip @username mention from the beginning of reply text
    private func stripReplyMention(from content: String, parentAuthorName: String?) -> String {
        guard let parentName = parentAuthorName else { return content }
        let mention = "@\(parentName) "
        if content.hasPrefix(mention) {
            return String(content.dropFirst(mention.count))
        }
        return content
    }
}
