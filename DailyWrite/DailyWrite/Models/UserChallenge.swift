import FirebaseFirestore
import SwiftUI

struct UserChallenge: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let challengeId: String
    let progress: Int
    let isCompleted: Bool
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case challengeId
        case progress
        case isCompleted
        case completedAt
        case createdAt
        case updatedAt
    }
    
    init(id: String? = nil,
         userId: String,
         challengeId: String,
         progress: Int,
         isCompleted: Bool,
         completedAt: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.progress = progress
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.challengeId = try container.decode(String.self, forKey: .challengeId)
        self.progress = try container.decode(Int.self, forKey: .progress)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct Challenge: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let requirement: Int
    let type: ChallengeType
    
    enum ChallengeType: String, Codable {
        case essayCount
        case streak
        case wordCount
        case publicEssays
        case morningWriting
        case nightWriting
    }
}
