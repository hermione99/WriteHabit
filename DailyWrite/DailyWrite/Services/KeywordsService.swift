import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing daily keywords/prompts
class KeywordsService {
    static let shared = KeywordsService()
    private let db = Firestore.firestore()
    
    /// Archive of past keywords with their dates
    struct KeywordArchive: Codable, Identifiable {
        let id: String  // date string as ID
        let keyword: String
        let date: Date
        let emoji: String
    }
    
    /// Save today's keyword to archive
    func saveDailyKeyword(_ keyword: String, date: Date = Date()) async throws {
        let dateString = ISO8601DateFormatter().string(from: date)
        let emoji = KeywordEmojiService.shared.emojiForKeyword(keyword)
        
        let archive = KeywordArchive(
            id: dateString,
            keyword: keyword,
            date: date,
            emoji: emoji
        )
        
        try await db.collection("keywordArchive")
            .document(dateString)
            .setData([
                "keyword": keyword,
                "date": Timestamp(date: date),
                "emoji": emoji
            ])
    }
    
    /// Get all past keywords (excluding today)
    func getPastKeywords() async throws -> [KeywordArchive] {
        let today = Calendar.current.startOfDay(for: Date())
        
        let snapshot = try await db.collection("keywordArchive")
            .whereField("date", isLessThan: Timestamp(date: today))
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            guard let keyword = doc.data()["keyword"] as? String,
                  let timestamp = doc.data()["date"] as? Timestamp,
                  let emoji = doc.data()["emoji"] as? String else {
                return nil
            }
            
            return KeywordArchive(
                id: doc.documentID,
                keyword: keyword,
                date: timestamp.dateValue(),
                emoji: emoji
            )
        }
    }
    
    /// Get past keywords that have essays
    func getKeywordsWithEssays() async throws -> [(keyword: KeywordArchive, essayCount: Int)] {
        let pastKeywords = try await getPastKeywords()
        
        // Get essay counts for each keyword
        var result: [(KeywordArchive, Int)] = []
        
        for keyword in pastKeywords {
            let count = try await getEssayCount(forKeyword: keyword.keyword)
            result.append((keyword, count))
        }
        
        return result
    }
    
    /// Get essay count for a specific keyword
    private func getEssayCount(forKeyword keyword: String) async throws -> Int {
        let snapshot = try await db.collection("essays")
            .whereField("keyword", isEqualTo: keyword)
            .whereField("isDraft", isEqualTo: false)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    /// Generate and save a keyword for today if not exists
    func ensureTodayKeyword() async throws -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = ISO8601DateFormatter().string(from: today)
        
        // Check if today's keyword exists
        let doc = try await db.collection("keywordArchive").document(dateString).getDocument()
        
        if let data = doc.data(), let keyword = data["keyword"] as? String {
            return keyword
        }
        
        // Generate new keyword
        let newKeyword = generateRandomKeyword()
        try await saveDailyKeyword(newKeyword, date: today)
        return newKeyword
    }
    
    /// Generate a random keyword (fallback)
    private func generateRandomKeyword() -> String {
        let keywords = [
            "Spring", "Journey", "Memory", "Dream", "Hope",
            "Reflection", "Joy", "Challenge", "Growth", "Peace",
            "Adventure", "Discovery", "Wisdom", "Courage", "Gratitude"
        ]
        return keywords.randomElement() ?? "Writing"
    }
}
