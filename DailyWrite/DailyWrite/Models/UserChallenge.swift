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
    let currentLevel: Int  // 현재 단계 (0부터 시작)
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case challengeId
        case progress
        case isCompleted
        case completedAt
        case createdAt
        case updatedAt
        case currentLevel
    }
    
    init(id: String? = nil,
         userId: String,
         challengeId: String,
         progress: Int,
         isCompleted: Bool,
         completedAt: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         currentLevel: Int = 0) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.progress = progress
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.currentLevel = currentLevel
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
        self.currentLevel = try container.decodeIfPresent(Int.self, forKey: .currentLevel) ?? 0
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
    let maxLevel: Int  // 최대 단계 (0이면 단계 없음)
    let requirementMultiplier: Int  // 단계별 요구량 배수 (레벨 1: requirement * 1, 레벨 2: requirement * 2...)
    
    // 현재 레벨의 요구량 계산
    func requirementForLevel(_ level: Int) -> Int {
        if maxLevel == 0 { return requirement }
        return requirement * (level + 1)
    }
    
    enum ChallengeType: String, Codable {
        case essayCount
        case streak
        case wordCount
        case publicEssays
        case morningWriting
        case nightWriting
        case punchCard  // 일일 키워드 전용
        
        var displayName: String {
            switch self {
            case .essayCount:
                return "Essays"
            case .streak:
                return "Streak"
            case .wordCount:
                return "Words"
            case .publicEssays:
                return "Public"
            case .morningWriting:
                return "Morning"
            case .nightWriting:
                return "Night"
            case .punchCard:
                return "Punch Card"
            }
        }
    }
}
