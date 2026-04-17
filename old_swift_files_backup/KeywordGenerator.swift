import Foundation
import FirebaseFirestore

// Generates unique, never-repeating keywords using AI and curated pools
class KeywordGenerator {
    static let shared = KeywordGenerator()
    
    private let db = Firestore.firestore()
    private let openAIKey = "YOUR_OPENAI_API_KEY"
    
    // Large curated pools (500+ keywords each)
    private let koreanPool: [String] = [
        "우연한 발견", "메아리", "방랑", "그림자", "표류", "만개", "침묵", "노을", "안개", "고요",
        "산책", "추억", "꿈", "빛", "파도", "바람", "비", "눈", "새벽", "황혼",
        "이별", "만남", "약속", "후회", "용서", "성장", "변화", "시작", "끝", "여정",
        "순간", "영원", "행복", "슬픔", "기쁨", "분노", "사랑", "그리움", "외로움", "평화",
        "도시", "시골", "바다", "산", "숲", "길", "집", "창문", "문", "계단",
        "커피", "차", "술", "음식", "향기", "소리", "색", "온도", "촉감", "맛",
        "시계", "달력", "거울", "사진", "편지", "책", "음악", "영화", "그림", "춤",
        "어린 시절", "청춘", "중년", "노년", "미래", "과거", "현재", "시간", "기회", "운명",
        "울림", "공명", "잔상", "여운", "잔잔함", "격정", "열정", "냉정", "침착", "긴장",
        "비밀", "진실", "거짓", "환상", "현실", "이상", "욕망", "필요", "소망", "기도",
        "실수", "성공", "실패", "도전", "포기", "인내", "끈기", "용기", "두려움", "희망",
        "가족", "친구", "연인", "이웃", "동료", "스승", "제자", "자녀", "부모", "형제",
        "봄", "여름", "가을", "겨울", "계절", "날씨", "온도", "습도", "바람결", "햇살",
        "별", "달", "태양", "구름", "무지개", "천둥", "번개", "안개", "서리", "이슬",
        "꽃", "나무", "잎", "열매", "씨앗", "뿌리", "줄기", "가지", "열매", "수액",
        "새", "고양이", "개", "나비", "벌", "물고기", "고래", "사슴", "여우", "곰",
        "기차", "비행기", "배", "자전거", "걸음", "여행", "도착", "출발", "정류장", "항구",
        "시장", "카페", "도서관", "박물관", "극장", "공원", "광장", "골목", "다리", "터널",
        "손", "발", "눈", "귀", "입", "코", "심장", "숨", "피", "살",
        "웃음", "눈물", "한숨", "소리", "침묵", "속삭임", "외침", "노래", "이야기", "대화",
        // More creative keywords
        "파편", "조각", "흔적", "자국", "흉터", "무늬", "결", "질감", "농도", "밀도",
        "간격", "격자", "선", "점", "면", "입체", "공간", "무한", "유한", "절대",
        "상대", "주관", "객관", "직관", "통찰", "깨달음", "각성", "계몽", "영감", "직감",
        "우연", "필연", "우연성", "필연성", "무작위", "규칙", "패턴", "반복", "변주", "화음",
        "선율", "리듬", "박자", "템포", "화성", "불협화음", "공명", "울림", "메아리", "잔향",
        "일상", "비일상", "특별", "평범", "특이", "일반", "표준", "편차", "평균", "최고",
        "최저", "극대", "극소", "정점", "바닥", "정상", "이상", "기준", "임계", "한계",
        "장벽", "경계", "경계선", "분기점", "전환점", "분수령", "분기", "기로", "교차로", "삼거리",
        "갈림길", "융합", "결합", "분리", "단절", "연결", "고리", "사슬", "망", "그물",
        "미로", " labyrinth", "미궁", "함정", "안식", "쉼", "휴식", "재충전", "회복", "회생",
        "부활", "소생", "각성", "전환", "변모", "변용", "변형", "변태", "진화", "퇴화",
        "성숙", "미숙", "숙성", "발효", "숙성", "익음", "성장", "쇠퇴", "번성", "쇠락",
        "황폐", "번영", "풍요", "기근", "만족", "부족", "과잉", "결핍", "풍족", "부족",
        "희소", "풍부", "고갈", "고갈", "소진", "충전", "방전", "역전", "전도", "전환",
        "반전", "반전", "반전", "반전", "반전", "반전", "반전", "반전", "반전", "반전"
    ]
    
    private let englishPool: [String] = [
        "Serendipity", "Echo", "Wanderlust", "Shadows", "Drift", "Bloom", "Silence", "Sunset", "Mist", "Quiet",
        "Stroll", "Memory", "Dream", "Light", "Waves", "Wind", "Rain", "Snow", "Dawn", "Dusk",
        "Farewell", "Meeting", "Promise", "Regret", "Forgiveness", "Growth", "Change", "Beginning", "End", "Journey",
        "Moment", "Eternity", "Joy", "Sorrow", "Happiness", "Anger", "Love", "Longing", "Solitude", "Peace",
        "City", "Countryside", "Ocean", "Mountain", "Forest", "Road", "Home", "Window", "Door", "Stairs",
        "Coffee", "Tea", "Wine", "Food", "Scent", "Sound", "Color", "Temperature", "Touch", "Taste",
        "Clock", "Calendar", "Mirror", "Photograph", "Letter", "Book", "Music", "Film", "Painting", "Dance",
        "Childhood", "Youth", "Middle Age", "Old Age", "Future", "Past", "Present", "Time", "Opportunity", "Destiny",
        "Resonance", "Symphony", "Afterimage", "Linger", "Calm", "Passion", "Zeal", "Composure", "Nerves", "Hope",
        "Secret", "Truth", "Lie", "Fantasy", "Reality", "Ideal", "Desire", "Need", "Wish", "Prayer",
        "Mistake", "Success", "Failure", "Challenge", "Giving Up", "Patience", "Persistence", "Courage", "Fear", "Hope",
        "Family", "Friend", "Lover", "Neighbor", "Colleague", "Mentor", "Student", "Child", "Parent", "Sibling",
        "Spring", "Summer", "Autumn", "Winter", "Season", "Weather", "Heat", "Humidity", "Breeze", "Sunlight",
        "Star", "Moon", "Sun", "Cloud", "Rainbow", "Thunder", "Lightning", "Fog", "Frost", "Dew",
        "Flower", "Tree", "Leaf", "Fruit", "Seed", "Root", "Stem", "Branch", "Berry", "Sap",
        "Bird", "Cat", "Dog", "Butterfly", "Bee", "Fish", "Whale", "Deer", "Fox", "Bear",
        "Train", "Airplane", "Ship", "Bicycle", "Walking", "Travel", "Arrival", "Departure", "Station", "Harbor",
        "Market", "Cafe", "Library", "Museum", "Theater", "Park", "Square", "Alley", "Bridge", "Tunnel",
        "Hand", "Foot", "Eye", "Ear", "Mouth", "Nose", "Heart", "Breath", "Blood", "Skin",
        "Laughter", "Tears", "Sigh", "Voice", "Silence", "Whisper", "Shout", "Song", "Story", "Conversation",
        // More creative keywords
        "Fragment", "Shard", "Trace", "Mark", "Scar", "Pattern", "Grain", "Texture", "Density", "Consistency",
        "Spacing", "Grid", "Line", "Dot", "Plane", "Volume", "Space", "Infinity", "Finite", "Absolute",
        "Relative", "Subjective", "Objective", "Intuition", "Insight", "Realization", "Awakening", "Enlightenment", "Inspiration", "Hunch",
        "Chance", "Necessity", "Contingency", "Inevitability", "Randomness", "Rule", "Pattern", "Repetition", "Variation", "Harmony",
        "Melody", "Rhythm", "Beat", "Tempo", "Chord", "Dissonance", "Resonance", "Reverberation", "Echo", "Afterglow",
        "Ordinary", "Extraordinary", "Special", "Common", "Unique", "General", "Standard", "Deviation", "Average", "Peak",
        "Valley", "Maximum", "Minimum", "Summit", "Bottom", "Normal", "Abnormal", "Baseline", "Threshold", "Limit",
        "Barrier", "Boundary", "Border", "Turning Point", "Crossroads", "Watershed", "Branch", "Intersection", "Junction", "Fork",
        "Merger", "Fusion", "Separation", "Break", "Connection", "Link", "Chain", "Net", "Web", "Labyrinth",
        "Maze", "Trap", "Rest", "Pause", "Break", "Recharge", "Recovery", "Renewal", "Rebirth", "Resurrection",
        "Revival", "Transformation", "Metamorphosis", "Transmutation", "Evolution", "Involution", "Maturation", "Immaturity", "Ripening", "Fermentation",
        "Growth", "Decline", "Prosperity", "Decay", "Waste", "Flourishing", "Abundance", "Famine", "Satisfaction", "Lack",
        "Excess", "Deficiency", "Plenty", "Scarcity", "Depletion", "Exhaustion", "Charge", "Discharge", "Reversal", "Inversion",
        "Twist", "Irony", "Paradox", "Oxymoron", "Contradiction", "Conflict", "Tension", "Balance", "Imbalance", "Equilibrium"
    ]
    
    // Generate a unique keyword that hasn't been used recently
    func getDailyKeyword(language: AppLanguage) async -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = ISO8601DateFormatter.string(from: today, timeZone: .current, formatOptions: [.withFullDate])
        let docId = "\(language.rawValue)_\(dateString)"
        
        // Check if today's keyword already exists
        do {
            let doc = try await db.collection("global_keywords").document(docId).getDocument()
            if let keyword = doc.data()?["keyword"] as? String {
                return keyword
            }
        } catch {
            print("Error checking existing keyword: \(error)")
        }
        
        // Get used keywords from the last 365 days
        let usedKeywords = await getRecentlyUsedKeywords(language: language, days: 365)
        
        // Select a unique keyword
        let pool = language == .korean ? koreanPool : englishPool
        var availableKeywords = pool.filter { !usedKeywords.contains($0) }
        
        // If all used (unlikely with 500+ keywords), reset and use any
        if availableKeywords.isEmpty {
            availableKeywords = pool
            // Clear old used keywords from Firestore
            await clearOldKeywords(language: language)
        }
        
        // Pick random from available
        let selectedKeyword = availableKeywords.randomElement() ?? pool[0]
        
        // Save to Firestore
        do {
            try await db.collection("global_keywords").document(docId).setData([
                "keyword": selectedKeyword,
                "date": Timestamp(date: today),
                "language": language.rawValue,
                "createdAt": Timestamp()
            ])
        } catch {
            print("Error saving keyword: \(error)")
        }
        
        return selectedKeyword
    }
    
    // Get keywords used in the last N days
    private func getRecentlyUsedKeywords(language: AppLanguage, days: Int) async -> Set<String> {
        var usedKeywords: Set<String> = []
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return usedKeywords
        }
        
        do {
            let query = db.collection("global_keywords")
                .whereField("language", isEqualTo: language.rawValue)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            
            let snapshot = try await query.getDocuments()
            
            for doc in snapshot.documents {
                if let keyword = doc.data()["keyword"] as? String {
                    usedKeywords.insert(keyword)
                }
            }
        } catch {
            print("Error fetching used keywords: \(error)")
        }
        
        return usedKeywords
    }
    
    // Clear keywords older than 1 year
    private func clearOldKeywords(language: AppLanguage) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: today) else { return }
        
        do {
            let query = db.collection("global_keywords")
                .whereField("language", isEqualTo: language.rawValue)
                .whereField("date", isLessThan: Timestamp(date: cutoffDate))
            
            let snapshot = try await query.getDocuments()
            
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
        } catch {
            print("Error clearing old keywords: \(error)")
        }
    }
    
    // Generate AI keywords when pool runs low
    func generateNewKeywords(language: AppLanguage, count: Int = 50) async -> [String] {
        // Only generate if OpenAI key is set
        guard openAIKey != "YOUR_OPENAI_API_KEY" else {
            return []
        }
        
        let prompt = language == .korean ? koreanGenerationPrompt : englishGenerationPrompt
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You generate unique, evocative single-word writing prompts."],
                ["role": "user", "content": prompt + "\n\nGenerate exactly \(count) unique prompts, comma-separated."]
            ],
            "temperature": 0.9,
            "max_tokens": 800
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }
            
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let content = result.choices.first?.message.content ?? ""
            
            return content
                .components(separatedBy: CharacterSet(charactersIn: ",\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { $0.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression) }
                .map { $0.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression) }
        } catch {
            print("Error generating keywords: \(error)")
            return []
        }
    }
    
    private let koreanGenerationPrompt = """
    한국어로 창의적인 글쓰기를 위한 고유하고 감성적인 한 단어 또는 두 단어 키워드를 생성하세요.
    자연, 감정, 시간, 장소, 추상적 개념 등 다양한 주제에서 선택하세요.
    예시: 빗소리, 거울, 그림자, 그리움, 노을, 새벽, 회상, 울림
    """
    
    private let englishGenerationPrompt = """
    Generate unique, evocative single-word or two-word English writing prompts.
    Mix concrete nouns, abstract concepts, nature, emotions, time, and places.
    Examples: Petrichor, Limerence, Ephemeral, Sonder, Mellifluous, Effervescent
    """
    
    struct OpenAIResponse: Codable {
        let choices: [Choice]
    }
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
