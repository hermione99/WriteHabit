import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EssayDetailView: View {
    let essay: Essay
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var authorProfile: UserProfile?
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var isLoading = false
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var showDeleteCommentConfirmation = false
    @State private var commentToDelete: Comment? = nil
    @State private var navigateToProfile = false
    @State private var selectedUserId: String? = nil
    @State private var selectedKeyword: String? = nil
    
    private let indigoColor = Color(hex: "0D244D")
    private let creamColor = Color(hex: "F5F0E8")
    
    // Computed property to check if current user is the author
    private var isCurrentUserAuthor: Bool {
        essay.authorId == Auth.auth().currentUser?.uid
    }
    
    init(essay: Essay) {
        self.essay = essay
        _likesCount = State(initialValue: essay.likesCount)
    }
    
    var body: some View {
        ZStack {
            // Beige/cream background for entire page
            creamColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Content (with paper texture)
                    contentSection
                    
                    // Stats
                    statsSection
                    
                    // Comments section (inline)
                    if !comments.isEmpty || essay.visibility == .public || essay.visibility == .friends {
                        commentsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Essay".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if isCurrentUserAuthor {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit".localized, systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete".localized, systemImage: "trash")
                        }
                    }
                    
                    Button {
                        // Share action
                    } label: {
                        Label("Share".localized, systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(indigoColor)
                }
            }
        }
        .alert("Delete Essay?".localized, isPresented: $showDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                deleteEssay()
            }
        } message: {
            Text("This action cannot be undone.".localized)
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            SimpleWritingEditorView(
                keyword: essay.keyword,
                existingEssay: essay
            )
        }
        .task {
            await loadAuthorProfile()
            await checkIfLiked()
            await loadComments()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Keyword badge - clickable
            Button {
                selectedKeyword = essay.keyword
            } label: {
                HStack {
                    Text(KeywordEmojiService.shared.emojiForKeyword(essay.keyword))
                        .font(.title2)
                    Text(essay.keyword)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(indigoColor.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(indigoColor.opacity(0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: Binding(
                get: { selectedKeyword != nil },
                set: { if !$0 { selectedKeyword = nil } }
            )) {
                if let keyword = selectedKeyword {
                    KeywordBrowseView(keyword: keyword)
                }
            }
            
            // Title with indigo line separator
            if !essay.title.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(essay.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(indigoColor)
                    
                    // Indigo line separator instead of box
                    Rectangle()
                        .fill(indigoColor.opacity(0.2))
                        .frame(height: 1)
                }
            }
            
            // Author info
            HStack(spacing: 12) {
                // Profile image
                if let photoUrl = authorProfile?.profilePhotoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(indigoColor.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(indigoColor.opacity(0.5))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(indigoColor.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(indigoColor.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(indigoColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(indigoColor.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authorProfile?.displayName ?? essay.authorName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(indigoColor)
                    
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundStyle(indigoColor.opacity(0.5))
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedUserId = essay.authorId
                navigateToProfile = true
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                if let userId = selectedUserId {
                    PublicProfileView(userId: userId)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        ZStack(alignment: .topLeading) {
            // Paper background with texture
            PaperWithTapeBackground()
            
            // Content text with rich text support
            if let attributedContent = essay.attributedContent {
                // Use Text with AttributedString for rich text
                Text(attributedContent)
                    .foregroundStyle(indigoColor.opacity(0.9))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 32)
                    .padding(.top, 20)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Fallback to plain text
                Text(fullContent)
                    .font(essayFont)
                    .lineSpacing(essayLineSpacing)
                    .foregroundStyle(indigoColor.opacity(0.9))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 32)
                    .padding(.top, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Paper with Tape Background
    private struct PaperWithTapeBackground: View {
        private let indigoColor = Color(hex: "0D244D")
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Base paper
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "FDFBF7"))
                    
                    // Paper texture - subtle grain
                    Canvas { context, size in
                        // Draw paper fibers/noise
                        for _ in 0..<3000 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let opacity = Double.random(in: 0.02...0.06)
                            let radius = CGFloat.random(in: 0.3...0.8)
                            
                            let rect = CGRect(x: x, y: y, width: radius, height: radius)
                            let path = Path(ellipseIn: rect)
                            context.fill(path, with: .color(Color(hex: "8B7355").opacity(opacity)))
                        }
                        
                        // Add subtle horizontal lines (like notebook paper but very faint)
                        let lineSpacing: CGFloat = 24
                        var y: CGFloat = 40
                        while y < size.height {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(Color(hex: "D4C4B0").opacity(0.3)), lineWidth: 0.5)
                            y += lineSpacing
                        }
                    }
                    
                    // Paper shadow/depth
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: "E8E0D5"), lineWidth: 1)
                    
                    // Top masking tape
                    VStack {
                        HStack {
                            // Left tape piece
                            MaskingTape()
                                .frame(width: 80, height: 24)
                                .rotationEffect(.degrees(-2))
                                .offset(x: 20, y: -12)
                            
                            Spacer()
                            
                            // Right tape piece (smaller)
                            MaskingTape()
                                .frame(width: 50, height: 20)
                                .rotationEffect(.degrees(3))
                                .offset(x: -30, y: -10)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Masking Tape View
    private struct MaskingTape: View {
        var body: some View {
            ZStack {
                // Tape base
                Rectangle()
                    .fill(Color(hex: "C4B9A8").opacity(0.7))
                
                // Tape texture
                Canvas { context, size in
                    // Fibrous texture
                    for _ in 0..<200 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let width = CGFloat.random(in: 2...8)
                        let opacity = Double.random(in: 0.1...0.25)
                        
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + width, y: y))
                        context.stroke(path, with: .color(Color(hex: "A09080").opacity(opacity)), lineWidth: 0.5)
                    }
                    
                    // Creases/wrinkles
                    for _ in 0..<3 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + CGFloat.random(in: -5...5), y: size.height))
                        context.stroke(path, with: .color(Color(hex: "B0A090").opacity(0.15)), lineWidth: 1)
                    }
                }
                
                // Tape edges (slightly darker)
                Rectangle()
                    .stroke(Color(hex: "B8ADA0").opacity(0.5), lineWidth: 0.5)
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 24) {
            // Likes
            Button {
                toggleLike()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(isLiked ? Color(hex: "C2441C") : indigoColor.opacity(0.4))
                    Text("\(likesCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(indigoColor.opacity(0.7))
                }
            }
            
            // Comments count
            HStack(spacing: 6) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 14))
                    .foregroundStyle(indigoColor.opacity(0.4))
                Text("\(essay.commentsCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(indigoColor.opacity(0.7))
            }
            
            // Word count
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(indigoColor.opacity(0.4))
                Text("\(essay.wordCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(indigoColor.opacity(0.7))
            }
            
            Spacer()
            
            // Visibility
            Image(systemName: essay.visibility == .public ? "globe" : "lock")
                .font(.system(size: 14))
                .foregroundStyle(indigoColor.opacity(0.4))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with count badge
            HStack(spacing: 8) {
                Text("댓글".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(indigoColor)
                
                if comments.count > 0 {
                    Text("\(comments.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(indigoColor)
                        )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(indigoColor.opacity(0.1))
            
            // Comments list - separate top-level and replies
            if comments.isEmpty {
                Text("No comments yet. Be the first to comment!".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(indigoColor.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Get top-level comments (no parent)
                    let topLevelComments = comments.filter { $0.parentCommentId == nil || $0.parentCommentId?.isEmpty == true }
                    
                    ForEach(topLevelComments) { comment in
                        // Find replies for this comment
                        let commentReplies = comments.filter { reply in
                            guard let replyParentId = reply.parentCommentId, !replyParentId.isEmpty,
                                  let commentId = comment.id else { return false }
                            return replyParentId == commentId
                        }
                        
                        // Top level comment with its replies
                        CommentRowView(
                            comment: comment,
                            replies: commentReplies,
                            onReply: { [self] replyContent in
                                guard let parentId = comment.id else {
                                    print("Error: Cannot reply - parent comment ID is nil")
                                    return
                                }
                                await postReply(parentCommentId: parentId, content: replyContent)
                            }
                        )
                        
                        if comment.id != topLevelComments.last?.id {
                            Divider()
                                .padding(.leading, 68)
                                .background(indigoColor.opacity(0.05))
                        }
                    }
                }
            }
            
            // Add comment input
            if essay.visibility == .public || essay.visibility == .friends || isCurrentUserAuthor {
                Divider()
                    .background(indigoColor.opacity(0.1))
                
                HStack(spacing: 12) {
                    // Current user profile placeholder
                    Circle()
                        .fill(indigoColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(indigoColor)
                                .font(.system(size: 16))
                        )
                    
                    TextField("Share your mind...".localized, text: $newComment)
                        .font(.system(size: 15))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(indigoColor.opacity(0.05))
                        )
                    
                    if !newComment.isEmpty {
                        Button {
                            postComment()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(indigoColor)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "FDFBF7"))
        )
    }
    
    // MARK: - Comment Row View
    private struct CommentRowView: View {
        let comment: Comment
        let replies: [Comment]
        let onReply: (String) async -> Void
        @State private var authorProfile: UserProfile?
        @State private var isLiked = false
        @State private var likeCount = 0
        @State private var showReplyField = false
        @State private var replyText = ""
        @State private var isSubmitting = false
        private let indigoColor = Color(hex: "0D244D")
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Main comment row
                HStack(alignment: .top, spacing: 12) {
                    // Profile image
                    profileImage
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Header: Name + Time
                        HStack {
                            Text(comment.authorName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(indigoColor)
                            
                            Spacer()
                            
                            Text(timeAgo(from: comment.createdAt))
                                .font(.system(size: 12))
                                .foregroundStyle(indigoColor.opacity(0.4))
                        }
                        
                        // Comment content
                        Text(comment.content)
                            .font(.system(size: 15))
                            .foregroundStyle(indigoColor)
                            .lineSpacing(2)
                            .padding(.top, 2)
                        
                        // Actions: Like + Reply
                        HStack(spacing: 16) {
                            Button {
                                // Toggle like
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .font(.system(size: 14))
                                    Text("\(likeCount)")
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(isLiked ? indigoColor : indigoColor.opacity(0.5))
                            }
                            
                            Button {
                                withAnimation {
                                    showReplyField.toggle()
                                }
                            } label: {
                                Text("Reply".localized)
                                    .font(.system(size: 13))
                                    .foregroundStyle(indigoColor.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Reply input field
                if showReplyField {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(indigoColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(indigoColor)
                                    .font(.system(size: 14))
                            )
                        
                        TextField("Write a reply...".localized, text: $replyText)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(indigoColor.opacity(0.05))
                            )
                        
                        if !replyText.isEmpty {
                            Button {
                                isSubmitting = true
                                Task {
                                    await onReply(replyText)
                                    isSubmitting = false
                                    showReplyField = false
                                    replyText = ""
                                }
                            } label: {
                                if isSubmitting {
                                    ProgressView()
                                        .frame(width: 28, height: 28)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(indigoColor)
                                }
                            }
                            .disabled(isSubmitting)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(indigoColor.opacity(0.03))
                }
                
                // Replies section
                if !replies.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(replies) { reply in
                            ReplyRowView(reply: reply)
                            
                            if reply.id != replies.last?.id {
                                Divider()
                                    .padding(.leading, 68)
                                    .background(indigoColor.opacity(0.03))
                            }
                        }
                    }
                    .padding(.leading, 56)
                }
            }
            .task {
                await loadAuthorProfile()
                likeCount = comment.likesCount ?? 0
            }
        }
        
        private var profileImage: some View {
            Group {
                if let photoUrl = authorProfile?.profilePhotoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Circle()
                                .fill(indigoColor.opacity(0.1))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(indigoColor)
                                )
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(indigoColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(indigoColor)
                                .font(.system(size: 20))
                        )
                }
            }
        }
        
        private func loadAuthorProfile() async {
            do {
                let profile = try await FirebaseService.shared.getUserProfile(userId: comment.authorId)
                await MainActor.run {
                    self.authorProfile = profile
                }
            } catch {
                print("Error loading author profile: \(error)")
            }
        }
        
        private func timeAgo(from date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    // MARK: - Reply Row View
    private struct ReplyRowView: View {
        let reply: Comment
        @State private var authorProfile: UserProfile?
        private let indigoColor = Color(hex: "0D244D")
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // Profile image
                if let photoUrl = authorProfile?.profilePhotoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Circle()
                                .fill(indigoColor.opacity(0.1))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(indigoColor)
                                )
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(indigoColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(indigoColor)
                                .font(.system(size: 16))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reply.authorName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(indigoColor)
                        
                        Spacer()
                        
                        Text(timeAgo(from: reply.createdAt))
                            .font(.system(size: 11))
                            .foregroundStyle(indigoColor.opacity(0.4))
                    }
                    
                    Text(reply.content)
                        .font(.system(size: 14))
                        .foregroundStyle(indigoColor)
                        .lineSpacing(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .task {
                await loadAuthorProfile()
            }
        }
        
        private func loadAuthorProfile() async {
            do {
                let profile = try await FirebaseService.shared.getUserProfile(userId: reply.authorId)
                await MainActor.run {
                    self.authorProfile = profile
                }
            } catch {
                print("Error loading author profile: \(error)")
            }
        }
        
        private func timeAgo(from date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    // MARK: - Attributed Text View
    private struct AttributedTextView: UIViewRepresentable {
        let attributedString: AttributedString
        var lineSpacing: CGFloat = 8
        var foregroundStyle: Color = .primary
        
        func makeUIView(context: Context) -> UITextView {
            let textView = UITextView()
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainer.widthTracksTextView = true
            return textView
        }
        
        func updateUIView(_ textView: UITextView, context: Context) {
            // Convert AttributedString to NSAttributedString
            let nsAttributedString = NSAttributedString(attributedString)
            
            // Apply additional paragraph styling for line spacing
            let mutableAttrString = NSMutableAttributedString(attributedString: nsAttributedString)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            
            mutableAttrString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: mutableAttrString.length)
            )
            
            textView.attributedText = mutableAttrString
            textView.textColor = UIColor(foregroundStyle)
            
            // Invalidate layout to force recalculation
            textView.setNeedsLayout()
            textView.layoutIfNeeded()
        }
        
        func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize {
            guard let width = proposal.width, width != .infinity, width > 0 else {
                return CGSize(width: proposal.width ?? 300, height: 0)
            }
            
            // Set the frame width
            uiView.frame.size.width = width
            
            // Force layout
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
            
            // Calculate size using bounding rect
            let nsString = NSAttributedString(attributedString)
            let boundingRect = nsString.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            let height = ceil(boundingRect.height) + 4 // Small buffer
            
            return CGSize(width: width, height: height)
        }
    }
    
    // MARK: - Helper Properties
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: essay.createdAt)
    }
    
    // Font properties based on writer's choice
    private var essayFont: Font {
        let fontSize = essay.fontSize ?? 16
        
        // Match AppFont rawValue format (with spaces)
        switch essay.fontName {
        case "KoPub Batang":
            return .custom("KoPubBatang-Regular.otf", size: fontSize)
        case "Nanum Myeongjo":
            return .custom("NanumMyeongjo-Regular.ttf", size: fontSize)
        case "Ridi Batang":
            return .custom("RIDIBatang-Regular.otf", size: fontSize)
        case "Nanum Gothic":
            return .custom("NanumGothic-Regular.ttf", size: fontSize)
        case "Pretendard":
            return .custom("Pretendard-Regular.otf", size: fontSize)
        case "KoPub Dotum":
            return .custom("KoPubDotum-Regular.otf", size: fontSize)
        case "Apple SD Gothic Neo":
            return .system(size: fontSize, weight: .regular, design: .default)
        case "System":
            return .system(size: fontSize)
        case "Serif":
            return .system(size: fontSize, design: .serif)
        case "Rounded":
            return .system(size: fontSize, design: .rounded)
        case "Monospaced":
            return .system(size: fontSize, design: .monospaced)
        case "Georgia":
            return .custom("Georgia", size: fontSize)
        case "Courier":
            return .custom("Courier", size: fontSize)
        default:
            return .system(size: fontSize)
        }
    }
    
    private var essayLineSpacing: CGFloat {
        CGFloat(essay.lineSpacing ?? 8)
    }
    
    // Helper to get full content, falling back to attributedContent if plain content is empty
    private var fullContent: String {
        // If plain content exists and has meaningful length, use it
        if !essay.content.isEmpty {
            return essay.content
        }
        
        // Otherwise, try to extract from attributed content
        if let attributedString = essay.attributedContent {
            return String(attributedString.characters)
        }
        
        return essay.content // Return whatever we have (even if empty)
    }
    
    // MARK: - Delete Essay
    private func deleteEssay() {
        guard let essayId = essay.id else { return }
        
        Task {
            do {
                try await FirebaseService.shared.deleteEssay(essayId: essayId)
                // Post notification BEFORE dismissing so other views can refresh
                NotificationCenter.default.post(name: .essayDeleted, object: essayId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error deleting essay: \(error)")
            }
        }
    }
    
    // MARK: - Methods
    private func loadAuthorProfile() async {
        do {
            let profile = try await FirebaseService.shared.getUserProfile(userId: essay.authorId)
            await MainActor.run {
                self.authorProfile = profile
            }
        } catch {
            print("Error loading author profile: \(error)")
        }
    }
    
    private func checkIfLiked() async {
        guard let essayId = essay.id else { return }
        do {
            let liked = try await FirebaseService.shared.hasLikedEssay(essayId: essayId)
            await MainActor.run {
                self.isLiked = liked
            }
        } catch {
            print("Error checking like status: \(error)")
        }
    }
    
    private func loadComments() async {
        guard let essayId = essay.id else { return }
        do {
            let fetchedComments = try await FirebaseService.shared.getComments(for: essayId)
            await MainActor.run {
                self.comments = fetchedComments
            }
        } catch {
            print("Error loading comments: \(error)")
        }
    }
    
    private func postComment() {
        guard let essayId = essay.id, !newComment.isEmpty else { return }
        
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
    
    private func postReply(parentCommentId: String?, content: String) {
        guard let essayId = essay.id else {
            print("Error posting reply: essay.id is nil")
            return
        }
        guard let parentId = parentCommentId else {
            print("Error posting reply: parentCommentId is nil")
            return
        }
        guard !content.isEmpty else {
            print("Error posting reply: content is empty")
            return
        }
        
        Task {
            do {
                try await FirebaseService.shared.addComment(
                    essayId: essayId,
                    content: content,
                    parentCommentId: parentId
                )
                await loadComments()
            } catch {
                print("Error posting reply: \(error)")
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func toggleLike() {
        guard let essayId = essay.id else { return }
        
        Task {
            do {
                if isLiked {
                    try await FirebaseService.shared.unlikeEssay(essayId: essayId)
                    await MainActor.run {
                        isLiked = false
                        likesCount -= 1
                    }
                } else {
                    try await FirebaseService.shared.likeEssay(essayId: essayId)
                    await MainActor.run {
                        isLiked = true
                        likesCount += 1
                    }
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        EssayDetailView(essay: Essay(
            id: "preview",
            authorId: "author",
            authorName: "Test Author",
            keyword: "봄",
            title: "Sample Essay",
            content: "This is a sample essay content for preview purposes.",
            wordCount: 10,
            visibility: .public,
            isDraft: false,
            createdAt: Date(),
            updatedAt: Date(),
            likesCount: 5,
            commentsCount: 2
        ))
    }
}
