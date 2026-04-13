import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let email: String
    var displayName: String
    var username: String
    var bio: String
    var blogUrl: String?
    var brunchUrl: String?
    var instagramUrl: String?
    var twitterUrl: String?
    var threadsUrl: String?
    let createdAt: Date
    var essayCount: Int
    var totalWordCount: Int
    var streakDays: Int
    var following: [String]
    var friends: [String]
    
    init(id: String? = nil, userId: String, email: String, displayName: String, username: String, bio: String, blogUrl: String? = nil, brunchUrl: String? = nil, instagramUrl: String? = nil, twitterUrl: String? = nil, threadsUrl: String? = nil, createdAt: Date, essayCount: Int = 0, totalWordCount: Int = 0, streakDays: Int = 0, following: [String] = [], friends: [String] = []) {
        self.id = id
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.blogUrl = blogUrl
        self.brunchUrl = brunchUrl
        self.instagramUrl = instagramUrl
        self.twitterUrl = twitterUrl
        self.threadsUrl = threadsUrl
        self.createdAt = createdAt
        self.essayCount = essayCount
        self.totalWordCount = totalWordCount
        self.streakDays = streakDays
        self.following = following
        self.friends = friends
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "email": email,
            "displayName": displayName,
            "username": username,
            "bio": bio,
            "createdAt": Timestamp(date: createdAt),
            "essayCount": essayCount,
            "totalWordCount": totalWordCount,
            "streakDays": streakDays,
            "following": following,
            "friends": friends
        ]
        if let blogUrl = blogUrl { dict["blogUrl"] = blogUrl }
        if let brunchUrl = brunchUrl { dict["brunchUrl"] = brunchUrl }
        if let instagramUrl = instagramUrl { dict["instagramUrl"] = instagramUrl }
        if let twitterUrl = twitterUrl { dict["twitterUrl"] = twitterUrl }
        if let threadsUrl = threadsUrl { dict["threadsUrl"] = threadsUrl }
        return dict
    }
}
