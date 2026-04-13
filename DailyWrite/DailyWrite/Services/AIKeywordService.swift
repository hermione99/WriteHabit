import Foundation

struct AIKeywordService {
    static let shared = AIKeywordService()
    
    private let openAIKey = "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" // User needs to add their key
    private let keywordsCollection = "generated_keywords"
    
    // Generate keywords using OpenAI API
    func generateKeywords(language: AppLanguage, count: Int = 30) async throws -> [String] {
        let prompt = language == .korean ? koreanPrompt : englishPrompt
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a creative writing assistant that generates evocative, poetic single-word or short-phrase writing prompts."],
                ["role": "user", "content": prompt + "\n\nGenerate exactly \(count) unique prompts."]
            ],
            "temperature": 0.8,
            "max_tokens": 500
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw KeywordError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw KeywordError.apiError
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = result.choices.first?.message.content ?? ""
        
        // Parse the comma-separated or newline-separated keywords
        let keywords = content
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression) }
            .map { $0.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression) }
        
        return Array(keywords.prefix(count))
    }
    
    // Save generated keywords to cache
    func cacheKeywords(_ keywords: [String], language: AppLanguage) {
        let key = "cached_\(language.rawValue)_keywords"
        let datesKey = "cached_\(language.rawValue)_dates"
        
        // Store keywords with their generation dates
        let keywordsWithDates = keywords.map { ["word": $0, "date": Date()] }
        
        if let existingData = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
            // Merge with existing
            let merged = existingData + keywordsWithDates
            UserDefaults.standard.set(merged, forKey: key)
        } else {
            UserDefaults.standard.set(keywordsWithDates, forKey: key)
        }
    }
    
    // Get keyword for a specific day
    func getDailyKeyword(language: AppLanguage, date: Date = Date()) -> String {
        let key = "cached_\(language.rawValue)_keywords"
        
        // First check if we have cached keywords
        if let cachedData = UserDefaults.standard.array(forKey: key) as? [[String: Any]],
           !cachedData.isEmpty {
            
            // Get day of year
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
            
            // Return keyword based on day
            let index = (dayOfYear - 1) % cachedData.count
            if let word = cachedData[index]["word"] as? String {
                return word
            }
        }
        
        // Fallback to default keywords
        return defaultKeyword(for: language, date: date)
    }
    
    // Check if we need more keywords
    func shouldGenerateMoreKeywords(language: AppLanguage) -> Bool {
        let key = "cached_\(language.rawValue)_keywords"
        let lastGenerationKey = "last_\(language.rawValue)_keyword_generation"
        
        if let cachedData = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
            // If we have less than 60 days worth, generate more
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let remainingDays = 365 - dayOfYear
            
            return cachedData.count < remainingDays + 30
        }
        
        // Check if we haven't generated in the last 7 days
        if let lastGeneration = UserDefaults.standard.object(forKey: lastGenerationKey) as? Date {
            let daysSinceGeneration = Calendar.current.dateComponents([.day], from: lastGeneration, to: Date()).day ?? 0
            return daysSinceGeneration >= 7
        }
        
        return true
    }
    
    // Mark when we last generated
    func markGenerationComplete(language: AppLanguage) {
        let key = "last_\(language.rawValue)_keyword_generation"
        UserDefaults.standard.set(Date(), forKey: key)
    }
    
    private func defaultKeyword(for language: AppLanguage, date: Date) -> String {
        let koreanKeywords = ["우연한 발견", "메아리", "방랑", "그림자", "표류", "만개", "침묵", "노을", "안개", "고요", "산책", "추억", "꿈", "빛", "파도", "바람", "비", "눈", "새벽", "황혼"]
        let englishKeywords = ["Serendipity", "Echo", "Wanderlust", "Shadows", "Drift", "Bloom", "Silence", "Sunset", "Mist", "Quiet", "Stroll", "Memory", "Dream", "Light", "Waves", "Wind", "Rain", "Snow", "Dawn", "Dusk"]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let keywords = language == .korean ? koreanKeywords : englishKeywords
        return keywords[dayOfYear % keywords.count]
    }
    
    private let englishPrompt = """
    Generate unique, evocative single-word or two-word writing prompts in English. These should inspire creative writing.
    
    Examples of good prompts:
    - Concrete: Rain, Mirror, Shadow, Waves, Ember, Threshold
    - Abstract: Serendipity, Longing, Solitude, Reverie, Epiphany
    - Nature: Twilight, Horizon, Petrichor, Aurora, Cascade
    - Emotional: Melancholy, Euphoria, Nostalgia, Wanderlust
    - Time: Midnight, Eternity, Moment, Dusk, Dawn
    
    Format: Return only a comma-separated list of words/phrases, no numbers or bullets.
    """
    
    private let koreanPrompt = """
    한국어로 창의적인 글쓰기를 위한 고유하고 감성적인 한 단어 또는 두 단어 키워드를 생성하세요.
    
    좋은 예시:
    - 구체적: 빗소리, 거울, 그림자, 파도, 불꽃, 문턱
    - 추상적: 그리움, 우연, 적막, 회상, 깨달음
    - 자연: 노을, 지평선, 안개, 폭포, 별빛
    - 감정: 향수, 황홀경, 쓸쓸함, 동경
    - 시간: 새벽, 황혼, 영원, 순간, 밤하늘
    
    형식: 쉼표로 구분된 단어 목록만 반환하고, 번호나 글머리 기호는 사용하지 마세요.
    """
    
    enum KeywordError: Error {
        case invalidURL
        case apiError
        case invalidResponse
    }
}

// OpenAI API Response structs
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}
