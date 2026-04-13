import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    // MARK: - Essays
    
    func createEssay(keyword: String, title: String, content: String, visibility: EssayVisibility, isDraft: Bool = false) async throws -> Essay {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let essay = Essay(
            id: nil,
            authorId: user.uid,
            authorName: user.displayName ?? user.email ?? "Anonymous",
            keyword: keyword,
            title: title,
            content: content,
            wordCount: content.filter { !$0.isWhitespace }.count,
            visibility: isDraft ? .private : visibility,
            isDraft: isDraft,
            createdAt: Date(),
            updatedAt: Date(),
            likesCount: 0,
            commentsCount: 0
        )
        
        let docRef = db.collection("essays").document()
        try await docRef.setData(essay.dictionary)
        
        return essay
    }
    
    func saveDraft(keyword: String, title: String, content: String) async throws -> Essay {
        return try await createEssay(keyword: keyword, title: title, content: content, visibility: .private, isDraft: true)
    }
    
    func updateDraft(essayId: String, title: String, content: String) async throws {
        let docRef = db.collection("essays").document(essayId)
        try await docRef.updateData([
            "title": title,
            "content": content,
            "wordCount": content.filter { !$0.isWhitespace }.count,
            "updatedAt": Timestamp(date: Date())
        ])
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
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("isDraft", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Essay.self) }
    }
    
    func getDailyEssays(limit: Int = 50) async throws -> [Essay] {
        // Query public essays
        let publicSnapshot = try await db.collection("essays")
            .whereField("visibility", isEqualTo: "public")
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        let publicEssays = publicSnapshot.documents.compactMap { try? $0.data(as: Essay.self) }
        
        // Query friends-only essays
        let friendsSnapshot = try await db.collection("essays")
            .whereField("visibility", isEqualTo: "friends")
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        let friendsEssays = friendsSnapshot.documents.compactMap { try? $0.data(as: Essay.self) }
        
        // Combine and sort
        var allEssays = publicEssays + friendsEssays
        allEssays.sort { $0.createdAt > $1.createdAt }
        
        return Array(allEssays.prefix(limit))
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
            
            essays.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: Essay.self) })
        }
        
        return essays.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getUserEssays(userId: String) async throws -> [Essay] {
        let snapshot = try await db.collection("essays")
            .whereField("authorId", isEqualTo: userId)
            .whereField("isDraft", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Essay.self) }
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
    
    func addComment(essayId: String, content: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        let comment = Comment(
            id: nil,
            essayId: essayId,
            authorId: user.uid,
            authorName: user.displayName ?? user.email ?? "Anonymous",
            content: content,
            createdAt: Date()
        )
        
        let batch = db.batch()
        
        let commentRef = db.collection("comments").document()
        batch.setData([
            "essayId": essayId,
            "authorId": user.uid,
            "authorName": comment.authorName,
            "content": content,
            "createdAt": Timestamp(date: Date())
        ], forDocument: commentRef)
        
        let essayRef = db.collection("essays").document(essayId)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: essayRef)
        
        try await batch.commit()
    }
    
    func getComments(for essayId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("essayId", isEqualTo: essayId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
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
    
    func updateEssay(essayId: String, title: String, content: String) async throws {
        let essayRef = db.collection("essays").document(essayId)
        try await essayRef.updateData([
            "title": title,
            "content": content,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func followUser(currentUserId: String, targetUserId: String) async throws {
        let userRef = db.collection("users").document(currentUserId)
        try await userRef.updateData([
            "following": FieldValue.arrayUnion([targetUserId])
        ])
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
        
        // Firebase 'in' query limited to 10 items, so we query in batches
        var allEssays: [Essay] = []
        let batchSize = 10
        var index = 0
        
        while index < following.count {
            let batch = Array(following[index..<min(index + batchSize, following.count)])
            let snapshot = try await db.collection("essays")
                .whereField("authorId", in: batch)
                .whereField("visibility", in: ["public", "friends"])
                .whereField("isDraft", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let essays = snapshot.documents.compactMap { try? $0.data(as: Essay.self) }
            allEssays.append(contentsOf: essays)
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
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Essay.self)
        }
    }
    
    // MARK: - Account Deletion
    
    func deleteEssay(essayId: String) async throws {
        try await db.collection("essays").document(essayId).delete()
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
