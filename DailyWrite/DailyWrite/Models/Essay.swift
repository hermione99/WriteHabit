import Foundation
import FirebaseFirestore

enum EssayVisibility: String, Codable, CaseIterable {
    case `private` = "private"
    case friends = "friends"
    case `public` = "public"
    
    var displayName: String {
        switch self {
        case .private:
            return "Private".localized
        case .friends:
            return "Friends Only".localized
        case .public:
            return "Public".localized
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
            return "Only you can see this".localized
        case .friends:
            return "Only your friends can see this".localized
        case .public:
            return "Everyone can see this".localized
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
    var deletedAt: Date?  // nil if not deleted, set when moved to Recently Deleted
    var fontName: String?  // Stores the font used (e.g., "system", "koPubBatang")
    var lineSpacing: Double? // Stores the line spacing used
    var fontSize: Double? // Stores the font size used
    var attributedContentData: String? // Stores rich text as base64 encoded AttributedString
    
    // Computed property to get AttributedString from stored data
    var attributedContent: AttributedString? {
        guard let base64String = attributedContentData,
              let data = Data(base64Encoded: base64String) else { return nil }
        return try? AttributedString(NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil))
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case authorName
        case keyword
        case title
        case content
        case wordCount
        case visibility
        case isDraft
        case createdAt
        case updatedAt
        case likesCount
        case commentsCount
        case deletedAt
        case fontName
        case lineSpacing
        case fontSize
        case attributedContentData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        keyword = try container.decode(String.self, forKey: .keyword)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        wordCount = try container.decode(Int.self, forKey: .wordCount)
        visibility = try container.decode(EssayVisibility.self, forKey: .visibility)
        isDraft = try container.decode(Bool.self, forKey: .isDraft)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        fontName = try container.decodeIfPresent(String.self, forKey: .fontName)
        lineSpacing = try container.decodeIfPresent(Double.self, forKey: .lineSpacing)
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize)
        
        // Handle attributedContentData - could be stored as String (base64) or might be missing
        do {
            attributedContentData = try container.decodeIfPresent(String.self, forKey: .attributedContentData)
        } catch {
            // If decoding fails (e.g., old data format), set to nil
            attributedContentData = nil
        }
    }
    
    // Regular init for creating new essays
    init(id: String?, authorId: String, authorName: String, keyword: String, title: String, content: String, wordCount: Int, visibility: EssayVisibility, isDraft: Bool, createdAt: Date, updatedAt: Date, likesCount: Int, commentsCount: Int, deletedAt: Date? = nil, fontName: String? = nil, lineSpacing: Double? = nil, fontSize: Double? = nil, attributedContentData: String? = nil) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.keyword = keyword
        self.title = title
        self.content = content
        self.wordCount = wordCount
        self.visibility = visibility
        self.isDraft = isDraft
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.deletedAt = deletedAt
        self.fontName = fontName
        self.lineSpacing = lineSpacing
        self.fontSize = fontSize
        self.attributedContentData = attributedContentData
    }
    
    // Backward compatibility
    var isPublic: Bool {
        visibility == .public
    }
    
    var isInRecentlyDeleted: Bool {
        deletedAt != nil
    }
    
    var daysUntilPermanentDelete: Int {
        guard let deletedAt = deletedAt else { return 0 }
        let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: deletedAt)!
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: thirtyDaysLater).day ?? 0
        return max(0, daysLeft)
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
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
        if let deletedAt = deletedAt {
            dict["deletedAt"] = Timestamp(date: deletedAt)
        }
        if let fontName = fontName {
            dict["fontName"] = fontName
        }
        if let lineSpacing = lineSpacing {
            dict["lineSpacing"] = lineSpacing
        }
        if let fontSize = fontSize {
            dict["fontSize"] = fontSize
        }
        if let attributedContentData = attributedContentData {
            // Store as base64 string for Firebase
            dict["attributedContentData"] = attributedContentData
        }
        print("DEBUG Essay.dictionary: \(dict)")
        return dict
    }
}

// Firestore-compatible initializer for manual decoding
extension Essay {
    init?(dictionary: [String: Any], documentId: String? = nil) {
        print("[DEBUG Essay.init] Attempting to decode dictionary with keys: \(dictionary.keys.sorted())")
        
        // Required fields with fallbacks
        guard let authorId = dictionary["authorId"] as? String,
              let authorName = dictionary["authorName"] as? String else {
            print("[DEBUG Essay.init] Missing authorId or authorName")
            return nil
        }
        
        let keyword = dictionary["keyword"] as? String ?? ""
        let title = dictionary["title"] as? String ?? ""
        let content = dictionary["content"] as? String ?? ""
        let wordCount = dictionary["wordCount"] as? Int ?? content.filter { !$0.isWhitespace }.count
        
        guard let visibilityString = dictionary["visibility"] as? String,
              let visibility = EssayVisibility(rawValue: visibilityString) else {
            print("[DEBUG Essay.init] Missing or invalid visibility")
            return nil
        }
        
        let isDraft = dictionary["isDraft"] as? Bool ?? false
        
        // Handle dates - try Timestamp first, then Date
        let createdAt: Date
        let updatedAt: Date
        
        if let createdTimestamp = dictionary["createdAt"] as? Timestamp {
            createdAt = createdTimestamp.dateValue()
        } else if let createdDate = dictionary["createdAt"] as? Date {
            createdAt = createdDate
        } else {
            print("[DEBUG Essay.init] Missing createdAt")
            return nil
        }
        
        if let updatedTimestamp = dictionary["updatedAt"] as? Timestamp {
            updatedAt = updatedTimestamp.dateValue()
        } else if let updatedDate = dictionary["updatedAt"] as? Date {
            updatedAt = updatedDate
        } else {
            print("[DEBUG Essay.init] Missing updatedAt")
            return nil
        }
        
        self.id = dictionary["id"] as? String ?? documentId
        self.authorId = authorId
        self.authorName = authorName
        self.keyword = keyword
        self.title = title
        self.content = content
        self.wordCount = wordCount
        self.visibility = visibility
        self.isDraft = isDraft
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likesCount = dictionary["likesCount"] as? Int ?? 0
        self.commentsCount = dictionary["commentsCount"] as? Int ?? 0
        
        if let deletedAtTimestamp = dictionary["deletedAt"] as? Timestamp {
            self.deletedAt = deletedAtTimestamp.dateValue()
        } else if let deletedAtDate = dictionary["deletedAt"] as? Date {
            self.deletedAt = deletedAtDate
        } else {
            self.deletedAt = nil
        }
        
        self.fontName = dictionary["fontName"] as? String
        self.lineSpacing = dictionary["lineSpacing"] as? Double
        self.fontSize = dictionary["fontSize"] as? Double
        
        // Handle attributedContentData - could be String or Data
        if let attributedDataString = dictionary["attributedContentData"] as? String {
            self.attributedContentData = attributedDataString
        } else {
            self.attributedContentData = nil
        }
        
        print("[DEBUG Essay.init] Successfully decoded essay: \(title)")
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let essayId: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
    var likesCount: Int?
    var likedBy: [String]?
    var parentCommentId: String?  // nil = top-level comment, non-nil = reply to another comment
    var repliesCount: Int?
}

struct Like: Identifiable, Codable {
    @DocumentID var id: String?
    let essayId: String
    let userId: String
    let createdAt: Date
}

// MARK: - Notification Types
enum NotificationType: String, Codable {
    case comment
    case reply
    case like
    case friendRequest
    case follow
}

struct InAppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String  // recipient
    let type: NotificationType
    let title: String
    let body: String
    let relatedId: String?  // essayId, commentId, etc.
    let isRead: Bool
    let createdAt: Date
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "body": body,
            "isRead": isRead,
            "createdAt": Timestamp(date: createdAt)
        ]
        if let relatedId = relatedId {
            dict["relatedId"] = relatedId
        }
        return dict
    }
}
