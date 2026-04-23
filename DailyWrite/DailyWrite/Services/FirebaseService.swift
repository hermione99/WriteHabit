import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    // MARK: - Essays
    
    func createEssay(keyword: String, title: String, content: String, visibility: EssayVisibility, isDraft: Bool = false, fontName: String? = nil, lineSpacing: Double? = nil, fontSize: Double? = nil, attributedContentData: String? = nil) async throws -> Essay {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Generate a unique call ID to track duplicates
        let callId = UUID().uuidString.prefix(8)
        print("[DEBUG createEssay #\(callId)] Creating essay - keyword: \(keyword), title: \(title.prefix(20))...")
        print("[DEBUG createEssay #\(callId)] isDraft: \(isDraft), visibility: \(visibility)")
        
        // Fetch user's profile to get username/displayName
        let userDoc = try? await db.collection("users").document(user.uid).getDocument()
        let username = userDoc?.data()?["username"] as? String
        let displayName = userDoc?.data()?["displayName"] as? String
        let authorName = username ?? displayName ?? user.displayName ?? user.email ?? "Anonymous"
        
        let essay = Essay(
            id: String?.none,
            authorId: user.uid,
            authorName: authorName,
            keyword: keyword,
            title: title,
            content: content,
            wordCount: content.filter { !$0.isWhitespace }.count,
            visibility: isDraft ? .private : visibility,
            isDraft: isDraft,
            createdAt: Date(),
            updatedAt: Date(),
            likesCount: 0,
            commentsCount: 0,
            deletedAt: nil,
            fontName: fontName,
            lineSpacing: lineSpacing,
            fontSize: fontSize,
            attributedContentData: attributedContentData
        )
        
        let docRef = db.collection("essays").document()
        print("[DEBUG createEssay #\(callId)] Writing to document: \(docRef.documentID)")
        print("[DEBUG createEssay #\(callId)] Content preview: \(content.prefix(50))...")
        
        // Write and verify
        try await docRef.setData(essay.dictionary)
        
        // Immediately verify the write
        let verifyDoc = try await docRef.getDocument()
        if verifyDoc.exists {
            print("[DEBUG createEssay #\(callId)] ✅ VERIFIED: Document exists in Firestore")
        } else {
            print("[DEBUG createEssay #\(callId)] ❌ ERROR: Document NOT FOUND after write!")
        }
        
        print("[DEBUG createEssay #\(callId)] Successfully created essay with ID: \(docRef.documentID)")
        
        var savedEssay = essay
        savedEssay.id = docRef.documentID
        return savedEssay
    }
    
    func saveDraft(keyword: String, title: String, content: String, fontName: String? = nil, lineSpacing: Double? = nil, fontSize: Double? = nil, attributedContentData: String? = nil) async throws -> Essay {
        return try await createEssay(keyword: keyword, title: title, content: content, visibility: .private, isDraft: true, fontName: fontName, lineSpacing: lineSpacing, fontSize: fontSize, attributedContentData: attributedContentData)
    }
    
    func updateDraft(essayId: String, title: String, content: String, fontName: String? = nil, lineSpacing: Double? = nil, fontSize: Double? = nil, attributedContentData: String? = nil) async throws {
        var data: [String: Any] = [
            "title": title,
            "content": content,
            "updatedAt": Timestamp(date: Date())
        ]
        if let attributedContentData = attributedContentData {
            data["attributedContentData"] = attributedContentData
        }
        if let fontName = fontName {
            data["fontName"] = fontName
        }
        if let lineSpacing = lineSpacing {
            data["lineSpacing"] = lineSpacing
        }
        if let fontSize = fontSize {
            data["fontSize"] = fontSize
        }
        let docRef = db.collection("essays").document(essayId)
        try await docRef.updateData(data)
    }
    
    func publishDraft(essayId: String, visibility: EssayVisibility) async throws {
        let docRef = db.collection("essays").document(essayId)
        try await docRef.updateData([
            "isDraft": false,
            "visibility": visibility.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func getUserDrafts(userId: String) async throws -> [Essay] {
        print("[DEBUG getUserDrafts] Querying drafts for user: \(userId)")
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("isDraft", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        print("[DEBUG getUserDrafts] Got \(snapshot.documents.count) documents")
        
        return snapshot.documents.compactMap { doc in
            do {
                var essay = try doc.data(as: Essay.self)
                // Manually assign ID if @DocumentID didn't work
                if essay.id == nil {
                    essay.id = doc.documentID
                }
                // Skip deleted drafts
                if essay.deletedAt != nil {
                    return nil
                }
                return essay
            } catch {
                print("[DEBUG getUserDrafts] Error decoding document \(doc.documentID): \(error)")
                return nil
            }
        }
    }
    
    // MARK: - One Essay Per Keyword Check
    
    func getPublishedEssayForKeyword(userId: String, keyword: String) async throws -> Essay? {
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("keyword", isEqualTo: keyword)
            .whereField("isDraft", isEqualTo: false)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else { return nil }
        
        var essay = try doc.data(as: Essay.self)
        if essay.id == nil {
            essay.id = doc.documentID
        }
        // Exclude deleted essays - user can write a new one if they deleted the old one
        if essay.deletedAt != nil {
            return nil
        }
        return essay
    }
    
    func hasPublishedEssayForKeyword(userId: String, keyword: String) async throws -> Bool {
        let essay = try await getPublishedEssayForKeyword(userId: userId, keyword: keyword)
        return essay != nil
    }
    
    func getDailyEssays(userId: String, limit: Int = 50) async throws -> [Essay] {
        // Get user's friends list
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let friends = userDoc.data()?["friends"] as? [String] ?? []
        let friendIds = Set(friends)
        
        // Query public essays
        let publicSnapshot = try await db.collection("essays")
            .whereField("visibility", isEqualTo: "public")
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        print("DEBUG getDailyEssays: Found \(publicSnapshot.documents.count) public essays")
        
        // Log the authorIds of found essays
        for doc in publicSnapshot.documents {
            let authorId = doc.data()["authorId"] as? String ?? "unknown"
            let title = doc.data()["title"] as? String ?? "no title"
            print("DEBUG: Essay by \(authorId): \(title.prefix(30))...")
        }
        
        let publicEssays = publicSnapshot.documents.compactMap { doc -> Essay? in
            // Skip deleted essays
            if doc.data()["deletedAt"] != nil {
                return nil
            }
            do {
                var essay = try doc.data(as: Essay.self)
                if essay.id == nil {
                    essay.id = doc.documentID
                }
                return essay
            } catch {
                // Fallback to manual decoding
                if var essay = Essay(dictionary: doc.data(), documentId: doc.documentID) {
                    if essay.id == nil { essay.id = doc.documentID }
                    return essay
                }
                return nil
            }
        }
        
        // Query friends-only essays - only from actual friends
        var friendsEssays: [Essay] = []
        
        if !friendIds.isEmpty {
            // Fetch friends-only essays in batches (Firestore limits 'in' to 10 items)
            let batches = stride(from: 0, to: friends.count, by: 10).map {
                Array(friends[$0..<min($0 + 10, friends.count)])
            }
            
            for batch in batches {
                let friendsSnapshot = try await db.collection("essays")
                    .whereField("authorId", in: batch)
                    .whereField("visibility", isEqualTo: "friends")
                    .whereField("isDraft", isEqualTo: false)
                    .order(by: "createdAt", descending: true)
                    .limit(to: limit)
                    .getDocuments()
                
                let batchEssays = friendsSnapshot.documents.compactMap { doc -> Essay? in
                    // Skip deleted essays
                    if doc.data()["deletedAt"] != nil {
                        return nil
                    }
                    do {
                        var essay = try doc.data(as: Essay.self)
                        if essay.id == nil { essay.id = doc.documentID }
                        return essay
                    } catch {
                        if var essay = Essay(dictionary: doc.data(), documentId: doc.documentID) {
                            if essay.id == nil { essay.id = doc.documentID }
                            return essay
                        }
                        return nil
                    }
                }
                
                friendsEssays.append(contentsOf: batchEssays)
            }
        }
        
        // Combine and sort
        var allEssays = publicEssays + friendsEssays
        allEssays.sort { $0.createdAt > $1.createdAt }
        
        return Array(allEssays.prefix(limit))
    }
    
    // Legacy function without userId (defaults to public only for security)
    func getDailyEssays(limit: Int = 50) async throws -> [Essay] {
        // Query public essays only when no userId provided
        let publicSnapshot = try await db.collection("essays")
            .whereField("visibility", isEqualTo: "public")
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return publicSnapshot.documents.compactMap { doc -> Essay? in
            do {
                var essay = try doc.data(as: Essay.self)
                if essay.id == nil { essay.id = doc.documentID }
                return essay
            } catch {
                if var essay = Essay(dictionary: doc.data(), documentId: doc.documentID) {
                    if essay.id == nil { essay.id = doc.documentID }
                    return essay
                }
                return nil
            }
        }
    }
    
    // MARK: - Get Single Essay
    
    func getEssay(id: String) async throws -> Essay? {
        let doc = try await db.collection("essays").document(id).getDocument()
        guard doc.exists else { return nil }
        
        do {
            var essay = try doc.data(as: Essay.self)
            if essay.id == nil { essay.id = doc.documentID }
            return essay
        } catch {
            // Fallback to manual decoding
            if var essay = Essay(dictionary: doc.data() ?? [:], documentId: doc.documentID) {
                if essay.id == nil { essay.id = doc.documentID }
                return essay
            }
            return nil
        }
    }
    
    func getFriendsEssays(friendIds: [String]) async throws -> [Essay] {
        guard !friendIds.isEmpty else { return [] }
        
        var essays: [Essay] = []
        
        // Batch fetch essays from friends (Firestore limits to 10 per 'in' query)
        let batches = stride(from: 0, to: friendIds.count, by: 10).map {
            Array(friendIds[$0..<min($0 + 10, friendIds.count)])
        }
        
        for batch in batches {
            let snapshot = try await db.collection("essays")
                .whereField("authorId", in: batch)
                .whereField("visibility", in: ["public", "friends"])
                .whereField("isDraft", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            essays.append(contentsOf: snapshot.documents.compactMap { doc in
                do {
                    var essay = try doc.data(as: Essay.self)
                    if essay.id == nil { essay.id = doc.documentID }
                    return essay
                } catch { return nil }
            })
        }
        
        return essays.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getUserEssays(userId: String) async throws -> [Essay] {
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        // Manual decoding with timestamp validation, include deleted essays for "recently deleted" feature
        var essays: [Essay] = []
        for doc in snapshot.documents {
            if var essay = try? await safelyDecodeEssay(from: doc) {
                // Ensure ID is set
                if essay.id == nil {
                    essay.id = doc.documentID
                }
                essays.append(essay)
            }
        }
        return essays
    }
    
    // MARK: - Essay Counts by Keyword
    
    func getEssayCountForKeyword(keyword: String) async throws -> Int {
        let snapshot = try await db.collection("essays")
            .whereField("keyword", isEqualTo: keyword)
            .whereField("isDraft", isEqualTo: false)
            .whereField("deletedAt", isEqualTo: NSNull())
            .count
            .getAggregation(source: .server)
        
        return Int(snapshot.count)
    }
    
    func getEssayCountsForKeywords(keywords: [String]) async throws -> [String: Int] {
        var counts: [String: Int] = [:]
        
        // Process in batches to avoid overwhelming Firestore
        for keyword in keywords {
            do {
                let count = try await getEssayCountForKeyword(keyword: keyword)
                counts[keyword] = count
            } catch {
                print("Error getting count for keyword '\(keyword)': \(error)")
                counts[keyword] = 0
            }
        }
        
        return counts
    }
    
    private func safelyDecodeEssay(from document: DocumentSnapshot) async throws -> Essay? {
        guard let data = document.data() else { return nil }
        
        // Validate timestamps before creating Essay
        guard let createdAt = data["createdAt"] as? Timestamp,
              let updatedAt = data["updatedAt"] as? Timestamp else {
            print("Skipping document with invalid timestamps: \(document.documentID)")
            return nil
        }
        
        // Check timestamp ranges for createdAt and updatedAt
        let createdSeconds = createdAt.seconds
        let updatedSeconds = updatedAt.seconds
        
        // Valid range: year 2000 to 2100
        guard createdSeconds > 946684800 && createdSeconds < 4102444800,
              updatedSeconds > 946684800 && updatedSeconds < 4102444800 else {
            print("Skipping document with out-of-range timestamps: \(document.documentID)")
            return nil
        }
        
        // Also check deletedAt if it exists
        if let deletedAt = data["deletedAt"] as? Timestamp {
            let deletedSeconds = deletedAt.seconds
            guard deletedSeconds > 946684800 && deletedSeconds < 4102444800 else {
                print("Skipping document with invalid deletedAt timestamp: \(document.documentID), seconds: \(deletedSeconds)")
                return nil
            }
        }
        
        // Now safe to decode
        var essay = try? document.data(as: Essay.self)
        // Ensure ID is set from document ID
        if essay?.id == nil {
            essay?.id = document.documentID
        }
        return essay
    }
    
    func getDailyEssaysWithAuthors(limit: Int = 50) async throws -> [(essay: Essay, author: UserProfile?)] {
        let essays = try await getDailyEssays(limit: limit)
        
        // Fetch unique author IDs
        let authorIds = Set(essays.map { $0.authorId })
        
        // Fetch all author profiles in parallel
        var authors: [String: UserProfile] = [:]
        try await withThrowingTaskGroup(of: (String, UserProfile?).self) { group in
            for authorId in authorIds {
                group.addTask {
                    do {
                        let profile = try await self.getUserProfile(userId: authorId)
                        return (authorId, profile)
                    } catch {
                        return (authorId, nil)
                    }
                }
            }
            
            for try await (authorId, profile) in group {
                if let profile = profile {
                    authors[authorId] = profile
                }
            }
        }
        
        return essays.map { essay in
            (essay: essay, author: authors[essay.authorId])
        }
    }
    
    func likeEssay(essayId: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        let likeRef = db.collection("likes").document("\(essayId)_\(user.uid)")
        let essayRef = db.collection("essays").document(essayId)
        
        try await db.runTransaction { transaction, errorPointer in
            transaction.setData([
                "essayId": essayId,
                "userId": user.uid,
                "createdAt": Timestamp(date: Date())
            ], forDocument: likeRef)
            
            transaction.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: essayRef)
            return nil
        }
    }
    
    func unlikeEssay(essayId: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        let likeRef = db.collection("likes").document("\(essayId)_\(user.uid)")
        let essayRef = db.collection("essays").document(essayId)
        
        try await db.runTransaction { transaction, errorPointer in
            transaction.deleteDocument(likeRef)
            transaction.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: essayRef)
            return nil
        }
    }
    
    func hasLikedEssay(essayId: String) async throws -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        
        let doc = try await db.collection("likes").document("\(essayId)_\(user.uid)").getDocument()
        return doc.exists
    }
    
    // MARK: - Comments
    
    func addComment(essayId: String, content: String, parentCommentId: String? = nil) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        // Fetch user's profile to get their username/nickname
        let userDoc = try? await db.collection("users").document(user.uid).getDocument()
        let username = userDoc?.data()?["username"] as? String
        let displayName = userDoc?.data()?["displayName"] as? String
        let authorName = username ?? displayName ?? user.displayName ?? user.email ?? "Anonymous"
        
        let batch = db.batch()
        
        let commentRef = db.collection("comments").document()
        var commentData: [String: Any] = [
            "essayId": essayId,
            "authorId": user.uid,
            "authorName": authorName,
            "content": content,
            "createdAt": Timestamp(date: Date()),
            "likesCount": 0,
            "likedBy": [],
            "repliesCount": 0
        ]
        
        if let parentId = parentCommentId {
            commentData["parentCommentId"] = parentId
            
            // Increment parent comment's replies count
            let parentRef = db.collection("comments").document(parentId)
            batch.updateData(["repliesCount": FieldValue.increment(Int64(1))], forDocument: parentRef)
        }
        
        batch.setData(commentData, forDocument: commentRef)
        
        // Increment essay's comment count
        let essayRef = db.collection("essays").document(essayId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: essayRef)
        
        try await batch.commit()
        
        // Send notifications after successful comment
        if let parentId = parentCommentId {
            // It's a reply - notify the parent comment author
            let parentComment = try? await db.collection("comments").document(parentId).getDocument()
            if let parentAuthorId = parentComment?.data()?["authorId"] as? String {
                await NotificationService.shared.notifyCommentAuthorOfReply(
                    parentCommentId: parentId,
                    parentCommentAuthorId: parentAuthorId,
                    replierName: authorName,
                    replyContent: content,
                    essayId: essayId
                )
            }
        } else {
            // It's a top-level comment - notify essay author
            let essay = try? await db.collection("essays").document(essayId).getDocument()
            if let essayAuthorId = essay?.data()?["authorId"] as? String {
                await NotificationService.shared.notifyEssayAuthorOfComment(
                    essayId: essayId,
                    essayAuthorId: essayAuthorId,
                    commenterName: authorName,
                    commentContent: content
                )
            }
        }
    }
    
    func getComments(for essayId: String) async throws -> [Comment] {
        #if DEBUG
        print("[DEBUG Firebase] Querying comments for essayId: \(essayId)")
        #endif
        
        // Fetch all comments for this essay (both top-level and replies)
        let snapshot = try await db.collection("comments")
            .whereField("essayId", isEqualTo: essayId)
            .getDocuments()
        
        #if DEBUG
        print("[DEBUG Firebase] Found \(snapshot.documents.count) comment documents")
        #endif
        
        var comments = snapshot.documents.compactMap { doc in
            do {
                var comment = try doc.data(as: Comment.self)
                // Ensure id is set from document ID
                if comment.id == nil {
                    comment.id = doc.documentID
                }
                #if DEBUG
                print("[DEBUG Firebase] Decoded comment: \(comment.content.prefix(30))...")
                #endif
                return comment
            } catch {
                #if DEBUG
                print("[DEBUG Firebase] Failed to decode comment: \(error)")
                print("[DEBUG Firebase] Doc data: \(doc.data())")
                #endif
                return nil
            }
        }
        
        // Sort manually by createdAt
        comments.sort { $0.createdAt < $1.createdAt }
        
        return comments
    }
    
    func deleteComment(commentId: String, essayId: String) async throws {
        let batch = db.batch()
        
        // Delete the comment
        let commentRef = db.collection("comments").document(commentId)
        batch.deleteDocument(commentRef)
        
        // Decrement the essay's comment count
        let essayRef = db.collection("essays").document(essayId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(-1))], forDocument: essayRef)
        
        try await batch.commit()
    }
    
    func likeComment(commentId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentRef = db.collection("comments").document(commentId)
        try await commentRef.updateData([
            "likesCount": FieldValue.increment(Int64(1)),
            "likedBy": FieldValue.arrayUnion([userId])
        ])
    }
    
    func unlikeComment(commentId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentRef = db.collection("comments").document(commentId)
        try await commentRef.updateData([
            "likesCount": FieldValue.increment(Int64(-1)),
            "likedBy": FieldValue.arrayRemove([userId])
        ])
    }
    
    // MARK: - User Profile
    
    // Check if username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespaces)
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: normalizedUsername)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.isEmpty
    }
    
    func createUserProfile(userId: String, email: String, displayName: String, username: String) async throws {
        let profile = UserProfile(
            userId: userId,
            email: email,
            displayName: displayName,
            username: username.lowercased().trimmingCharacters(in: .whitespaces),
            bio: "Daily writer exploring thoughts one prompt at a time.",
            createdAt: Date()
        )
        
        try await db.collection("users").document(userId).setData(profile.dictionary)
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return try? doc.data(as: UserProfile.self)
    }
    
    func updateUserProfile(userId: String, displayName: String? = nil, bio: String? = nil, blogUrl: String? = nil, brunchUrl: String? = nil, instagramUrl: String? = nil, twitterUrl: String? = nil, threadsUrl: String? = nil) async throws {
        var updates: [String: Any] = [:]
        if let displayName = displayName {
            updates["displayName"] = displayName
        }
        if let bio = bio {
            updates["bio"] = bio
        }
        if let blogUrl = blogUrl {
            updates["blogUrl"] = blogUrl.isEmpty ? FieldValue.delete() : blogUrl
        }
        if let brunchUrl = brunchUrl {
            updates["brunchUrl"] = brunchUrl.isEmpty ? FieldValue.delete() : brunchUrl
        }
        if let instagramUrl = instagramUrl {
            updates["instagramUrl"] = instagramUrl.isEmpty ? FieldValue.delete() : instagramUrl
        }
        if let twitterUrl = twitterUrl {
            updates["twitterUrl"] = twitterUrl.isEmpty ? FieldValue.delete() : twitterUrl
        }
        if let threadsUrl = threadsUrl {
            updates["threadsUrl"] = threadsUrl.isEmpty ? FieldValue.delete() : threadsUrl
        }
        
        if !updates.isEmpty {
            try await db.collection("users").document(userId).updateData(updates)
        }
    }
    
    func updateUserProfilePhoto(userId: String, photoUrl: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "profilePhotoUrl": photoUrl,
            "profilePhotoUpdatedAt": Timestamp(date: Date())
        ])
    }
    
    func updateUserStats(userId: String, wordCount: Int) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "essayCount": FieldValue.increment(Int64(1)),
            "totalWordCount": FieldValue.increment(Int64(wordCount)),
            "lastEssayDate": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Update Essay Visibility
    
    func updateEssayVisibility(essayId: String, visibility: EssayVisibility) async throws {
        let essayRef = db.collection("essays").document(essayId)
        try await essayRef.updateData([
            "visibility": visibility.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Update Essay Content
    
    func updateEssay(essayId: String, title: String, content: String, fontName: String? = nil, lineSpacing: Double? = nil, fontSize: Double? = nil, attributedContentData: String? = nil) async throws {
        let essayRef = db.collection("essays").document(essayId)
        var data: [String: Any] = [
            "title": title,
            "content": content,
            "updatedAt": Timestamp(date: Date())
        ]
        if let fontName = fontName {
            data["fontName"] = fontName
        }
        if let lineSpacing = lineSpacing {
            data["lineSpacing"] = lineSpacing
        }
        if let fontSize = fontSize {
            data["fontSize"] = fontSize
        }
        if let attributedContentData = attributedContentData {
            data["attributedContentData"] = attributedContentData
        }
        try await essayRef.updateData(data)
    }
    
    func followUser(currentUserId: String, targetUserId: String) async throws {
        let userRef = db.collection("users").document(currentUserId)
        try await userRef.updateData([
            "following": FieldValue.arrayUnion([targetUserId])
        ])
        
        // Send notification to the followed user
        await NotificationService.shared.notifyUserOfFollow(
            followerId: currentUserId,
            targetUserId: targetUserId
        )
    }
    
    func unfollowUser(currentUserId: String, targetUserId: String) async throws {
        let userRef = db.collection("users").document(currentUserId)
        try await userRef.updateData([
            "following": FieldValue.arrayRemove([targetUserId])
        ])
    }
    
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(currentUserId).getDocument()
        guard let following = doc.data()?["following"] as? [String] else { return false }
        return following.contains(targetUserId)
    }
    
    func getFollowingEssays(userId: String) async throws -> [Essay] {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let following = userDoc.data()?["following"] as? [String], !following.isEmpty else {
            return []
        }
        
        // Get friends list separately for visibility filtering
        let friends = userDoc.data()?["friends"] as? [String] ?? []
        let friendIds = Set(friends)
        
        // Firebase 'in' query limited to 10 items, so we query in batches
        var allEssays: [Essay] = []
        let batchSize = 10
        var index = 0
        
        while index < following.count {
            let batch = Array(following[index..<min(index + batchSize, following.count)])
            
            // Query for public essays from people you follow
            let publicSnapshot = try await db.collection("essays")
                .whereField("authorId", in: batch)
                .whereField("visibility", isEqualTo: "public")
                .whereField("isDraft", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let publicEssays: [Essay] = publicSnapshot.documents.compactMap { doc in
                do {
                    var essay = try doc.data(as: Essay.self)
                    if essay.id == nil { essay.id = doc.documentID }
                    // Filter out deleted essays
                    if essay.deletedAt != nil { return nil }
                    return essay
                } catch { return nil }
            }
            allEssays.append(contentsOf: publicEssays)
            
            // Query for friends-only essays from actual friends
            let friendBatch = batch.filter { friendIds.contains($0) }
            if !friendBatch.isEmpty {
                let friendsSnapshot = try await db.collection("essays")
                    .whereField("authorId", in: friendBatch)
                    .whereField("visibility", isEqualTo: "friends")
                    .whereField("isDraft", isEqualTo: false)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 20)
                    .getDocuments()
                
                let friendsEssays: [Essay] = friendsSnapshot.documents.compactMap { doc in
                    do {
                        var essay = try doc.data(as: Essay.self)
                        if essay.id == nil { essay.id = doc.documentID }
                        // Filter out deleted essays
                        if essay.deletedAt != nil { return nil }
                        return essay
                    } catch { return nil }
                }
                allEssays.append(contentsOf: friendsEssays)
            }
            
            index += batchSize
        }
        
        // Sort combined results
        return allEssays.sorted { $0.createdAt > $1.createdAt }.prefix(50).map { $0 }
    }
    
    // MARK: - Date Range Query
    
    func getUserEssaysInDateRange(userId: String, startDate: Date, endDate: Date) async throws -> [Essay] {
        let query = db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("isDraft", isEqualTo: false)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("createdAt", isLessThan: Timestamp(date: endDate))
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        var essays: [Essay] = []
        for doc in snapshot.documents {
            if let essay = try? await safelyDecodeEssay(from: doc) {
                // Skip if essay is in recently deleted
                if essay.deletedAt == nil {
                    essays.append(essay)
                }
            }
        }
        return essays
    }
    
    // MARK: - Month Query
    
    func getEssaysForMonth(userId: String, date: Date) async throws -> [Essay] {
        let calendar = Calendar.current
        
        // Get first day of month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        // Get first day of next month
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        // Use the existing date range query
        return try await getUserEssaysInDateRange(userId: userId, startDate: startOfMonth, endDate: startOfNextMonth)
    }
    
    // MARK: - Soft Delete (Recently Deleted)
    
    func softDeleteEssay(essayId: String) async throws {
        print("🔥 Firebase: Soft deleting essay \(essayId)")
        let data: [String: Any] = [
            "deletedAt": Timestamp(date: Date())
        ]
        try await db.collection("essays").document(essayId).updateData(data)
        print("✅ Firebase: Essay soft deleted successfully")
    }
    
    func recoverEssay(essayId: String) async throws {
        let data: [String: Any] = [
            "deletedAt": FieldValue.delete()
        ]
        try await db.collection("essays").document(essayId).updateData(data)
    }
    
    func permanentlyDeleteEssay(essayId: String) async throws {
        try await db.collection("essays").document(essayId).delete()
    }
    
    func getRecentlyDeletedEssays(userId: String) async throws -> [Essay] {
        print("🔥 Firebase: Fetching recently deleted essays for user \(userId)")
        
        // Fetch all user's essays and filter manually to avoid invalid timestamps
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments()
        
        print("🔥 Firebase: Found \(snapshot.documents.count) total essays")
        
        // Filter for deleted essays with valid timestamps
        var essays: [Essay] = []
        for doc in snapshot.documents {
            guard let data = doc.data() as? [String: Any],
                  data["deletedAt"] != nil,
                  let deletedAt = data["deletedAt"] as? Timestamp else { continue }
            
            // Check if deletedAt is valid (year 2000-2100)
            let seconds = deletedAt.seconds
            guard seconds > 946684800 && seconds < 4102444800 else {
                print("⚠️ Skipping essay with invalid deletedAt: \(doc.documentID), seconds: \(seconds)")
                continue
            }
            
            if let essay = try? await safelyDecodeEssay(from: doc) {
                essays.append(essay)
            }
        }
        
        // Sort by deletedAt descending
        essays.sort { $0.deletedAt! > $1.deletedAt! }
        
        print("✅ Firebase: Returning \(essays.count) valid deleted essays")
        return essays
    }
    
    // MARK: - Account Deletion
    
    func deleteEssay(essayId: String) async throws {
        // Keep for backward compatibility - now uses soft delete
        try await softDeleteEssay(essayId: essayId)
    }
    
    func publishDraft(essayId: String) async throws {
        let essayRef = db.collection("essays").document(essayId)
        try await essayRef.updateData([
            "isDraft": false,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func deleteUserProfile(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
    
    // MARK: - Challenges
    
    func getUserChallenges(userId: String) async throws -> [UserChallenge] {
        let snapshot = try await db.collection("challenges")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: UserChallenge.self)
        }
    }
    
    func saveUserChallenge(_ challenge: UserChallenge) async throws {
        let data: [String: Any] = [
            "userId": challenge.userId,
            "challengeId": challenge.challengeId,
            "progress": challenge.progress,
            "isCompleted": challenge.isCompleted,
            "completedAt": challenge.completedAt != nil ? Timestamp(date: challenge.completedAt!) : NSNull(),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let id = challenge.id {
            try await db.collection("challenges").document(id).updateData(data)
        } else {
            var newData = data
            newData["createdAt"] = Timestamp(date: Date())
            try await db.collection("challenges").addDocument(data: newData)
        }
    }
    
    func completeChallenge(userId: String, challengeId: String) async throws {
        // Find existing challenge
        let snapshot = try await db.collection("challenges")
            .whereField("userId", isEqualTo: userId)
            .whereField("challengeId", isEqualTo: challengeId)
            .getDocuments()
        
        let data: [String: Any] = [
            "isCompleted": true,
            "completedAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let doc = snapshot.documents.first {
            try await doc.reference.updateData(data)
        } else {
            // Create new completed challenge
            var newData = data
            newData["userId"] = userId
            newData["challengeId"] = challengeId
            newData["progress"] = 1
            newData["createdAt"] = Timestamp(date: Date())
            try await db.collection("challenges").addDocument(data: newData)
        }
    }
    
    // MARK: - Username Search
    
    func getUserProfileByUsername(_ username: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        
        return snapshot.documents.first.flatMap { try? $0.data(as: UserProfile.self) }
    }
}
