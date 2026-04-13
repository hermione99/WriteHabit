import Foundation
import FirebaseFirestore

enum EssayVisibility: String, Codable, CaseIterable {
    case `private` = "private"
    case friends = "friends"
    case `public` = "public"
    
    var displayName: String {
        switch self {
        case .private:
            return "Private"
        case .friends:
            return "Friends Only"
        case .public:
            return "Public"
        }
    }
    
    var icon: String {
        switch self {
        case .private:
            return "lock.fill"
        case .friends:
            return "person.2.fill"
        case .public:
            return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .private:
            return "Only you can see this"
        case .friends:
            return "Only your friends can see this"
        case .public:
            return "Everyone can see this"
        }
    }
}

struct Essay: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let authorId: String
    let authorName: String
    let keyword: String
    let title: String
    let content: String
    let wordCount: Int
    let visibility: EssayVisibility
    let isDraft: Bool
    let createdAt: Date
    let updatedAt: Date
    var likesCount: Int
    var commentsCount: Int
    
    // Backward compatibility
    var isPublic: Bool {
        visibility == .public
    }
    
    var dictionary: [String: Any] {
        let dict: [String: Any] = [
            "authorId": authorId,
            "authorName": authorName,
            "keyword": keyword,
            "title": title,
            "content": content,
            "wordCount": wordCount,
            "visibility": visibility.rawValue,
            "isDraft": isDraft,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "likesCount": likesCount,
            "commentsCount": commentsCount
        ]
        print("DEBUG Essay.dictionary: \(dict)")
        return dict
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let essayId: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
}

struct Like: Identifiable, Codable {
    @DocumentID var id: String?
    let essayId: String
    let userId: String
    let createdAt: Date
}
