import FirebaseFirestore
import FirebaseAuth

class FriendsService {
    static let shared = FriendsService()
    private let db = Firestore.firestore()
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        guard currentUserId != userId else {
            throw FriendsError.cannotAddSelf
        }
        
        // Check if already friends
        let isFriend = try await isFriend(with: userId)
        if isFriend {
            throw FriendsError.alreadyFriends
        }
        
        // Check if request already exists
        let existingRequest = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !existingRequest.documents.isEmpty {
            throw FriendsError.requestAlreadySent
        }
        
        // Create friend request
        let request = FriendRequest(
            id: nil,
            fromUserId: currentUserId,
            toUserId: userId,
            status: .pending,
            createdAt: Date()
        )
        
        try await db.collection("friendRequests").addDocument(from: request)
    }
    
    func acceptFriendRequest(_ requestId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Update request status
        try await db.collection("friendRequests").document(requestId).updateData([
            "status": "accepted"
        ])
        
        // Get the request to find the other user
        let requestDoc = try await db.collection("friendRequests").document(requestId).getDocument()
        guard let request = try? requestDoc.data(as: FriendRequest.self) else {
            throw FriendsError.requestNotFound
        }
        
        let friendId = request.fromUserId == currentUserId ? request.toUserId : request.fromUserId
        
        // Add to both users' friends list
        try await db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
        
        try await db.collection("users").document(friendId).updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ])
    }
    
    func declineFriendRequest(_ requestId: String) async throws {
        try await db.collection("friendRequests").document(requestId).updateData([
            "status": "declined"
        ])
    }
    
    // MARK: - Get Friends
    
    func getFriends() async throws -> [UserProfile] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let userProfile = try? userDoc.data(as: UserProfile.self) else {
            return []
        }
        
        let friendIds = userProfile.friends
        
        if friendIds.isEmpty {
            return []
        }
        
        // Batch fetch friends (Firestore limits to 10 per 'in' query)
        var friends: [UserProfile] = []
        let batches = stride(from: 0, to: friendIds.count, by: 10).map {
            Array(friendIds[$0..<min($0 + 10, friendIds.count)])
        }
        
        for batch in batches {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            let batchFriends = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
            friends.append(contentsOf: batchFriends)
        }
        
        return friends
    }
    
    func getPendingRequests() async throws -> [FriendRequest] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        let snapshot = try await db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: FriendRequest.self) }
    }
    
    func getSentRequests() async throws -> [FriendRequest] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        let snapshot = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: FriendRequest.self) }
    }
    
    // MARK: - Check Status
    
    func isFriend(with userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let userProfile = try? userDoc.data(as: UserProfile.self) else {
            return false
        }
        
        return userProfile.friends.contains(userId)
    }
    
    func getFriendRequestStatus(with userId: String) async throws -> FriendRequestStatus {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Check for pending request from current user
        let sentSnapshot = try await db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !sentSnapshot.documents.isEmpty {
            return .requestSent
        }
        
        // Check for pending request to current user
        let receivedSnapshot = try await db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !receivedSnapshot.documents.isEmpty {
            return .requestReceived
        }
        
        return .none
    }
    
    // MARK: - Remove Friend
    
    func removeFriend(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Remove from both users' friends lists
        try await db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayRemove([userId])
        ])
        
        try await db.collection("users").document(userId).updateData([
            "friends": FieldValue.arrayRemove([currentUserId])
        ])
    }
    
    // MARK: - Share Essay with Friend
    
    func shareEssay(_ essay: Essay, with friendId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Check if they are actually friends
        let isFriend = try await isFriend(with: friendId)
        guard isFriend else {
            throw FriendsError.notFriends
        }
        
        // Create shared essay record
        let sharedEssay = SharedEssay(
            id: nil,
            essayId: essay.id ?? "",
            fromUserId: currentUserId,
            toUserId: friendId,
            essay: essay,
            sharedAt: Date(),
            isRead: false
        )
        
        try await db.collection("sharedEssays").addDocument(from: sharedEssay)
    }
    
    func getSharedEssays() async throws -> [SharedEssay] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        let snapshot = try await db.collection("sharedEssays")
            .whereField("toUserId", isEqualTo: currentUserId)
            .order(by: "sharedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: SharedEssay.self) }
    }
    
    func markSharedEssayAsRead(_ sharedEssayId: String) async throws {
        try await db.collection("sharedEssays").document(sharedEssayId).updateData([
            "isRead": true
        ])
    }
}

// MARK: - Models

struct FriendRequest: Codable, Identifiable {
    @DocumentID var id: String?
    let fromUserId: String
    let toUserId: String
    let status: RequestStatus
    let createdAt: Date
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
}

struct SharedEssay: Codable, Identifiable {
    @DocumentID var id: String?
    let essayId: String
    let fromUserId: String
    let toUserId: String
    let essay: Essay
    let sharedAt: Date
    let isRead: Bool
}

enum FriendRequestStatus {
    case none
    case requestSent
    case requestReceived
    case friends
}

enum FriendsError: Error {
    case notAuthenticated
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent
    case requestNotFound
    case notFriends
}
