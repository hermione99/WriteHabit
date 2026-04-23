import Foundation
import FirebaseFirestore

extension KeywordsService {
    /// Get display keyword for a date - Firestore first, then fallback
    func getDisplayKeyword(for date: Date, language: AppLanguage = .korean) async -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        let docId = language == .korean ? "ko_\(dateString)" : "en_\(dateString)"
        
        // Try Firestore first (for past/saved keywords)
        do {
            let doc = try await db.collection("global_keywords").document(docId).getDocument()
            if let data = doc.data(), let keyword = data["keyword"] as? String {
                return keyword
            }
        } catch {
            print("[DEBUG] Firestore keyword not found for \(dateString), using fallback")
        }
        
        // Fallback to hash-based (for future dates)
        return getStableKeyword(for: date, language: language)
    }
    
    /// Get all keywords for a month (async)
    func getKeywordsForMonth(date: Date, language: AppLanguage = .korean) async -> [Date: String] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
        
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return [:]
        }
        
        var keywords: [Date: String] = [:]
        var currentDate = monthStart
        
        while currentDate < monthEnd {
            let keyword = await getDisplayKeyword(for: currentDate, language: language)
            keywords[currentDate] = keyword
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return keywords
    }
}
