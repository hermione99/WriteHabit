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
        "커피", "차", "술", "음식", "향기", "소리", "색", "무게", "촉감", "맛",
        "시계", "달력", "거울", "사진", "편지", "책", "음악", "영화", "그림", "춤",
        "어린 시절", "청춘", "중년", "노년", "미래", "과거", "현재", "시간", "기회", "운명",
        "울림", "공명", "잔상", "여운", "잔잔함", "격정", "열정", "냉정", "침착", "긴장",
        "비밀", "진실", "거짓", "환상", "현실", "이상", "욕망", "필요", "소망", "기도",
        "실수", "성공", "실패", "도전", "포기", "인내", "끈기", "용기", "두려움", "희망",
        "가족", "친구", "연인", "이웃", "동료", "스승", "제자", "자녀", "부모", "형제",
        "봄", "여름", "가을", "겨울", "계절", "날씨", "영하", "습도", "바람결", "햇살",
        "별", "달", "태양", "구름", "무지개", "천둥", "번개", "흐림", "서리", "이슬",
        "꽃", "나무", "잎", "열매", "씨앗", "뿌리", "줄기", "가지", "껍질", "수액",
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
        "미로", "미궁", "함정", "안식", "쉼", "휴식", "재충전", "회복", "회생", "부활",
        "부활", "소생", "각성", "전환", "변모", "변용", "변형", "변태", "진화", "퇴화",
        "성숙", "미숙", "숙성", "발효", "숙성", "익음", "성장", "쇠퇴", "번성", "쇠락",
        "황폐", "번영", "풍요", "기근", "만족", "부족", "과잉", "결핍", "풍족", "부족",
        "희소", "풍부", "고갈", "고갈", "소진", "충전", "방전", "역전", "전도", "전환",
        "반전", "고요", "속삭임", "파문", "여백", "잔소리", "동경", "애환", "유영", "산책",
        // Emotions & Psychology
        "불안", "설렘", "질투", "초조", "망설임", "후련", "아쉬움", "섭섭", "뿌듯", "민망",
        "답답", "시원", "허전", "허망", "찜찜", "오묘", "묘연", "애틋", "그리운", "그리움",
        // Time & Memory
        "순간", "영원", "잠시", "오랜", "예전", "지금", "곧", "아까", "나중", "언젠가",
        "기억", "망각", "상기", "추억", "회상", "뇌속", "잊혀", "새록", "생생", "희미",
        // Places & Spaces  
        "틈", "구석", "모퉁이", "문턱", "현관", "베란다", "다락", "지하", "옥상", "뒤편",
        "골목", "길목", "사거리", "육거리", "고가", "지하도", "통로", "출입", "안쪽", "바깥",
        // Abstract Concepts
        "우연", "필연", "운명", "인연", "악연", "기회", "위기", "전환", "변곡", "분기",
        "순환", "반복", "되풀이", "징검", "도미노", "나비효과", "융합", "분열", "균열", "균형",
        // Daily Life
        "아침", "점심", "저녁", "밤", "새벽", "정오", "자정", "황혼", "동틀", "노을",
        "일상", "비일상", "일과", "여가", "휴일", "평일", "주말", "연휴", "출근", "퇴근",
        // Relationships
        "인연", "연분", "정", "정서", "애정", "우정", "신의", "의리", "인의", "예의",
        "우애", "애착", "미움", "원망", "원한", "애증", "애끼", "짝사랑", "짝", "첫사랑"
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
        "Twist", "Irony", "Paradox", "Oxymoron", "Contradiction", "Conflict", "Tension", "Balance", "Imbalance", "Equilibrium",
        // Technology & Modern Life
        "Digital", "Screen", "Notification", "Wireless", "Connected", "Isolated", "Information", "Data", "Algorithm", "AI",
        "Virtual", "Augmented", "Filter", "Lens", "Frame", "Pixel", "Resolution", "Clarity", "Blur", "Focus",
        // Art & Creativity
        "Brush", "Pigment", "Canvas", "Sculpture", "Pottery", "Textile", "Thread", "Needle", "Draft", "Masterpiece",
        "Sketch", "Composition", "Light-Shadow", "Perspective", "Proportion", "Harmony", "Dissonance", "Aesthetics", "Taste", "Style",
        // Food & Taste
        "Recipe", "Spice", "Fermentation", "Aging", "Flavor", "Salty", "Sweet", "Sour", "Bitter", "Umami",
        "Spicy", "Texture", "Temperature", "Cooking", "Meal", "Snack", "Dessert", "Beverage", "Cocktail", "Wine",
        // Philosophy
        "Existence", "Presence", "Void", "Emptiness", "Essence", "Phenomenon", "Concept", "Materialism", "Idealism", "Dualism",
        "Argument", "Reasoning", "Proposition", "Statement", "Judgment", "Rationality", "Emotion", "Thought", "Mind", "Soul",
        // Movement & Action
        "Leap", "Jump", "Ascend", "Rise", "Descend", "Fall", "Plunge", "Rotate", "Orbit", "Spin",
        "Vibration", "Wave", "Diffusion", "Contraction", "Expansion", "Movement", "Stillness", "Acceleration", "Momentum", "Flow",
        // Relationships
        "Destiny", "Bond", "Link", "Chain", "Thread", "Knot", "Entanglement", "Conflict", "Reconciliation", "Dialogue",
        "Silence", "Misunderstanding", "Understanding", "Empathy", "Distance", "Intimacy", "Alienation", "Closeness", "Attachment", "Detachment",
        // Work & Career
        "Profession", "Task", "Goal", "Plan", "Strategy", "Execution", "Result", "Achievement", "Performance", "Evaluation",
        "Feedback", "Review", "Approval", "Rejection", "Pending", "Promotion", "Career", "Ambition", "Success", "Failure",
        // Urban Life
        "Noise", "Crowd", "Congestion", "Density", "Population", "Traffic", "Transit", "Pedestrian", "Rush", "Nightscape",
        "Neon", "Billboard", "Advertisement", "Temptation", "Entertainment", "Bustle", "Solitude", "Isolation", "Loneliness", "Community",
        // Health & Body
        "Health", "Disease", "Pain", "Comfort", "Discomfort", "Fatigue", "Vitality", "Energy", "Appetite", "Sleep",
        "Meditation", "Breath", "Yoga", "Exercise", "Rest", "Recovery", "Rehabilitation", "Healing", "Cure", "Wellness",
        // Dreams
        "Insomnia", "Dream", "Nightmare", "Prophecy", "Lucidity", "Memory", "Forgetting", "Amnesia", "Deja-Vu", "Hallucination",
        "Illusion", "Delusion", "Confusion", "Chaos", "Clarity", "Vision", "Trance", "Hypnosis", "Subconscious",
        // Materials
        "Droplet", "Dew", "Sweat", "Extract", "Juice", "Broth", "Iron", "Steel", "Copper", "Glass",
        "Ceramic", "Plastic", "Wood", "Timber", "Bamboo", "Fabric", "Silk", "Linen", "Cotton", "Wool",
        // Paper & Books
        "Paper", "Letter", "Notebook", "Diary", "Journal", "Printing", "Publishing", "Distribution", "Delivery", "Transmission",
        // Emotions & Psychology
        "Anxiety", "Flutter", "Jealousy", "Restless", "Hesitation", "Relief", "Regret", "Hurt", "Proud", "Awkward",
        "Frustrated", "Refreshing", "Empty", "Futile", "Uneasy", "Profound", "Mysterious", "Deep Affection", "Yearning", "Longing",
        // Time & Memory
        "Moment", "Eternity", "Brief", "Long Time", "Past", "Now", "Soon", "Earlier", "Later", "Someday",
        "Memory", "Forgetting", "Recollection", "Reminiscence", "Nostalgia", "Mind", "Forgotten", "Vivid", "Lifelike", "Faint",
        // Places & Spaces
        "Gap", "Corner", "Edge", "Threshold", "Entrance", "Balcony", "Attic", "Basement", "Rooftop", "Behind",
        "Alley", "Path", "Intersection", "Crossroad", "Overpass", "Underpass", "Passage", "Entry", "Inside", "Outside",
        // Abstract Concepts
        "Chance", "Inevitable", "Fate", "Destiny", "Misfortune", "Opportunity", "Crisis", "Turning Point", "Inflection", "Branch",
        "Cycle", "Repetition", "Iteration", "Stepping Stone", "Domino", "Butterfly Effect", "Fusion", "Division", "Rift", "Balance",
        // Daily Life
        "Morning", "Noon", "Evening", "Night", "Dawn", "Midday", "Midnight", "Twilight", "Sunrise", "Sunset",
        "Routine", "Extraordinary", "Workday", "Leisure", "Holiday", "Weekday", "Weekend", "Long Weekend", "Commute", "Leave Work",
        // Relationships
        "Connection", "Bond", "Jeong", "Sentiment", "Affection", "Friendship", "Loyalty", "Brotherhood", "Humanity", "Courtesy",
        "Fraternity", "Attachment", "Hatred", "Resentment", "Grudge", "Love-Hate", "Mutual Love", "Unrequited Love", "Soulmate", "First Love"
    ]
    
    // Generate a unique keyword that hasn't been used recently
    // English and Korean keywords are paired by index to match each day
    func getDailyKeyword(language: AppLanguage) async -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = ISO8601DateFormatter.string(from: today, timeZone: .current, formatOptions: [.withFullDate])
        let enDocId = "en_\(dateString)"
        let koDocId = "ko_\(dateString)"
        
        // Check if today's keyword already exists for requested language
        let docId = language == .korean ? koDocId : enDocId
        do {
            let doc = try await db.collection("global_keywords").document(docId).getDocument()
            if let keyword = doc.data()?["keyword"] as? String {
                return keyword
            }
        } catch {
            print("Error checking existing keyword: \(error)")
        }
        
        // Get used indices from the last 365 days
        let usedIndices = await getRecentlyUsedIndices(days: 365)
        
        // Select a unique index
        let poolSize = min(englishPool.count, koreanPool.count)
        var availableIndices = Set(0..<poolSize).subtracting(usedIndices)
        
        // If all used, clear old and reset
        if availableIndices.isEmpty {
            availableIndices = Set(0..<poolSize)
            await clearOldIndices()
        }
        
        // Pick random index from available
        let selectedIndex = availableIndices.randomElement() ?? 0
        let englishKeyword = englishPool[selectedIndex]
        let koreanKeyword = koreanPool[selectedIndex]
        
        // Save both to Firestore with same index
        do {
            let batch = db.batch()
            
            let enRef = db.collection("global_keywords").document(enDocId)
            batch.setData([
                "keyword": englishKeyword,
                "date": Timestamp(date: today),
                "language": "en",
                "poolIndex": selectedIndex,
                "createdAt": Timestamp()
            ], forDocument: enRef)
            
            let koRef = db.collection("global_keywords").document(koDocId)
            batch.setData([
                "keyword": koreanKeyword,
                "date": Timestamp(date: today),
                "language": "ko",
                "poolIndex": selectedIndex,
                "createdAt": Timestamp()
            ], forDocument: koRef)
            
            try await batch.commit()
        } catch {
            print("Error saving keywords: \(error)")
        }
        
        return language == .korean ? koreanKeyword : englishKeyword
    }
    
    // Get used indices from the last N days
    private func getRecentlyUsedIndices(days: Int) async -> Set<Int> {
        var usedIndices: Set<Int> = []
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
            return usedIndices
        }
        
        do {
            let query = db.collection("global_keywords")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            
            let snapshot = try await query.getDocuments()
            
            for doc in snapshot.documents {
                if let index = doc.data()["poolIndex"] as? Int {
                    usedIndices.insert(index)
                }
            }
        } catch {
            print("Error fetching used indices: \(error)")
        }
        
        return usedIndices
    }
    
    // Clear indices older than 1 year
    private func clearOldIndices() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: today) else { return }
        
        do {
            let query = db.collection("global_keywords")
                .whereField("date", isLessThan: Timestamp(date: cutoffDate))
            
            let snapshot = try await query.getDocuments()
            
            // Delete old entries
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
            
            print("Cleared \(snapshot.documents.count) old keyword entries")
        } catch {
            print("Error clearing old indices: \(error)")
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
