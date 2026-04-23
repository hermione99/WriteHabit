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

    /// Get past keywords that have essays (using pre-calculated stats)
    func getKeywordsWithEssays() async throws -> [(keyword: KeywordArchive, essayCount: Int)] {
        let pastKeywords = try await getPastKeywords()

        // Fetch all keyword stats in one query
        let statsSnapshot = try await db.collection("keywordStats")
            .getDocuments()

        // Create lookup dictionary
        var countsByKeyword: [String: Int] = [:]
        for doc in statsSnapshot.documents {
            if let count = doc.data()["essayCount"] as? Int, count > 0 {
                countsByKeyword[doc.documentID] = count
            }
        }

        // Filter and sort keywords
        let result = pastKeywords.compactMap { keyword -> (KeywordArchive, Int)? in
            guard let count = countsByKeyword[keyword.keyword], count > 0 else { return nil }
            return (keyword, count)
        }.sorted { $0.1 > $1.1 }  // Sort by essay count descending

        return result
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

        // Generate NEW keyword using AI every day
        do {
            let aiKeywords = try await AIKeywordService.shared.generateKeywords(language: .korean, count: 1)
            if let newKeyword = aiKeywords.first {
                try await saveDailyKeyword(newKeyword, date: today)
                return newKeyword
            }
        } catch {
            print("[ERROR] AI keyword generation failed: \(error). Falling back to pool.")
        }

        // Fallback to pool if AI fails
        let fallbackKeyword = generateRandomKeyword()
        try await saveDailyKeyword(fallbackKeyword, date: today)
        return fallbackKeyword
    }

    /// Get keyword for a specific date in the specified language
    func getKeywordForDate(_ date: Date, language: AppLanguage) async throws -> String {
        let dateString = ISO8601DateFormatter().string(from: date)
        let docId = language == .korean ? "ko_\(dateString)" : "en_\(dateString)"

        // Try global_keywords first (has both languages)
        let doc = try await db.collection("global_keywords").document(docId).getDocument()

        if let data = doc.data(), let keyword = data["keyword"] as? String {
            return keyword
        }

        // Fallback: Use KeywordGenerator's pools for consistent historical keywords
        let poolIndex = abs(dateString.hashValue) % 100 // Deterministic index from date
        let generator = KeywordGenerator.shared

        // Access pools through a computed approach
        let englishPool = [
            "Spring", "Journey", "Memory", "Dream", "Hope", "Reflection", "Joy", "Challenge",
            "Growth", "Peace", "Adventure", "Change", "Wisdom", "Gratitude", "Wonder",
            "Morning", "Evening", "Rain", "Sunshine", "Ocean", "Mountain", "Forest",
            "River", "Star", "Moon", "Home", "Family", "Friendship", "Love", "Courage"
        ]

        let koreanPool = [
            "봄", "여름", "가을", "겨울", "여정", "추억", "꿈", "희망", "성찰", "기쁨",
            "도전", "성장", "평화", "모험", "변화", "지혜", "감사", "경이로움", "아침", "저녁",
            "비", "햇살", "바다", "산", "숲", "강", "별", "달", "태양", "구름",
            "무지개", "천둥", "안개", "서리", "눈꽃", "바람", "파도", "노을", "새벽", "황혼",
            "사랑", "우정", "가족", "집", "만남", "이별", "기다림", "그리움", "행복", "슬픔",
            "용기", "결심", "믿음", "용서", "격려", "위로", "설렘", "소망", "인연", "인생",
            "여행", "독서", "음악", "요리", "산책", "운동", "창작", "그림", "사진", "일기",
            "커피", "차", "꽃", "나무", "새", "고양이", "강아지", "책", "편지", "선물",
            "시간", "순간", "기회", "선택", "후회", "반성", "깨달음", "명상", "집중",
            "목표", "계획", "실천", "노력", "인내", "열정", "포기", "도약", "전환", "재시작",
            "진실", "거짓", "선", "악", "아름다움", "추함", "강함", "약함", "시작", "끝",
            "원인", "결과", "운명", "우연", "필연", "자유", "속박", "평등", "차이", "통합",
            "발견", "탐구", "질문", "답", "비밀", "상상", "현실", "과거", "현재", "미래",
            "젊음", "노년", "건강", "상처", "치유", "평온", "혼란", "질서", "규칙", "예외",
            "전통", "혁신", "보수", "진보", "조화", "균형", "성취", "성공", "실패", "교훈",
            "배움", "가르침", "스승", "제자", "리더", "추종", "협력", "경쟁", "승리", "패배",
            "기쁨", "즐거움", "재미", "유쾌", "행운", "불운", "위기", "기회", "도전", "극복",
            "휴식", "여유", "바쁨", "쉼", "고요", "소음", "적막", "활기", "생기", "에너지",
            "빛", "어둠", "그림자", "형상", "색채", "선", "면", "입체", "공간", "시간",
            "속도", "거리", "방향", "목적지", "출발", "도착", "경유", "정차", "직행", "환승",
            "온도", "습도", "날씨", "기후", "환경", "생태", "자연", "인공", "도시", "시골",
            "바쁨", "한가로움", "적적함", "외로움", "함께함", "동행", "나홀로", "고독", "외톨이", "공동체",
            "소속", "정체성", "개성", "특성", "공통점", "차이점", "유사", "상이", "동일", "다름",
            "전체", "부분", "포함", "배제", "내부", "외부", "표면", "깊이", "넓이", "높이",
            "무게", "밀도", "질량", "부피", "공간", "차원", "세계", "우주", "은하", "태양계",
            "지구", "대륙", "바다", "섬", "반도", "해협", "만", "곶", "산맥", "평원",
            "고원", "분지", "협곡", "동굴", "폭포", "온천", "화산", "지진", "해일", "태풍"
        ]

        let safeIndex = poolIndex % koreanPool.count
        let keyword = language == .korean ? koreanPool[safeIndex] : englishPool[safeIndex % englishPool.count]

        // Save this keyword to global_keywords for future consistency
        let batch = db.batch()
        let enRef = db.collection("global_keywords").document("en_\(dateString)")
        batch.setData([
            "keyword": englishPool[safeIndex],
            "date": Timestamp(date: date),
            "language": "en",
            "poolIndex": safeIndex,
            "createdAt": Timestamp()
        ], forDocument: enRef, merge: true)

        let koRef = db.collection("global_keywords").document("ko_\(dateString)")
        batch.setData([
            "keyword": koreanPool[safeIndex],
            "date": Timestamp(date: date),
            "language": "ko",
            "poolIndex": safeIndex,
            "createdAt": Timestamp()
        ], forDocument: koRef, merge: true)

        try await batch.commit()

        return keyword
    }

    /// Get keyword for a specific date using stable hash (sync version)
    /// This matches the calculation used in DailyPromptView
    func getStableKeyword(for date: Date, language: AppLanguage = .korean) -> String {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        // Stable hash
        let stableHash = ((year * 365 + month * 31 + day) * 9301 + 49297) % 233280

        // Use full 365 pool to avoid duplicates
        let englishPool = [
            "Spring", "Summer", "Autumn", "Winter", "Journey", "Memory", "Dream", "Hope", "Reflection", "Joy",
            "Challenge", "Growth", "Peace", "Adventure", "Change", "Wisdom", "Gratitude", "Wonder", "Morning", "Evening",
            "Rain", "Sunshine", "Ocean", "Mountain", "Forest", "River", "Star", "Moon", "Sun", "Cloud",
            "Rainbow", "Thunder", "Fog", "Frost", "Snowflake", "Wind", "Wave", "Sunset", "Dawn", "Dusk",
            "Love", "Friendship", "Family", "Home", "Meeting", "Farewell", "Waiting", "Longing", "Happiness", "Sorrow",
            "Courage", "Determination", "Faith", "Forgiveness", "Encouragement", "Comfort", "Excitement", "Wish", "Connection", "Life",
            "Travel", "Reading", "Music", "Cooking", "Walking", "Exercise", "Creation", "Painting", "Photography", "Diary",
            "Coffee", "Tea", "Flower", "Tree", "Bird", "Cat", "Dog", "Book", "Letter", "Gift",
            "Time", "Moment", "Opportunity", "Choice", "Regret", "Introspection", "Insight", "Meditation", "Focus",
            "Goal", "Plan", "Action", "Effort", "Patience", "Passion", "GivingUp", "Leap", "Transition", "Restart",
            "Truth", "Lie", "Good", "Evil", "Beauty", "Ugliness", "Strength", "Weakness", "Beginning", "End",
            "Cause", "Result", "Destiny", "Coincidence", "Inevitability", "Freedom", "Constraint", "Equality", "Difference", "Unity",
            "Discovery", "Exploration", "Question", "Answer", "Secret", "Imagination", "Reality", "Past", "Present", "Future",
            "Youth", "OldAge", "Health", "Wound", "Healing", "Tranquility", "Chaos", "Order", "Rule", "Exception",
            "Tradition", "Innovation", "Conservative", "Progressive", "Harmony", "Balance", "Achievement", "Success", "Failure", "Lesson",
            "Learning", "Teaching", "Mentor", "Student", "Leader", "Follower", "Cooperation", "Competition", "Victory", "Defeat",
            "Pleasure", "Fun", "Amusement", "Cheerfulness", "Luck", "Misfortune", "Crisis", "Chance", "Challenge", "Overcoming",
            "Rest", "Leisure", "Busyness", "Pause", "Silence", "Noise", "Stillness", "Vitality", "Vigor", "Energy",
            "Light", "Darkness", "Shadow", "Shape", "Color", "Line", "Plane", "Solid", "Space", "Time",
            "Speed", "Distance", "Direction", "Destination", "Departure", "Arrival", "Stopover", "Stay", "Direct", "Transfer",
            "Temperature", "Humidity", "Weather", "Climate", "Environment", "Ecology", "Nature", "Artificial", "City", "Country",
            "Loneliness", "Togetherness", "Companionship", "Solitude", "Community",
            "Belonging", "Identity", "Individuality", "Characteristic", "Similarity", "Difference",
            "Whole", "Part", "Inclusion", "Exclusion", "Inside", "Outside", "Surface", "Depth", "Width", "Height",
            "Weight", "Density", "Mass", "Volume", "Dimension", "World", "Universe", "Galaxy", "SolarSystem", "Earth",
            "Continent", "Sea", "Island", "Peninsula", "Strait", "Bay", "Cape", "MountainRange", "Plain", "Plateau",
            "Basin", "Valley", "Cave", "Waterfall", "HotSpring", "Volcano", "Earthquake", "Tsunami", "Typhoon", "Birth",
            "Death", "Rebirth", "Renewal", "Metamorphosis", "Evolution", "Revolution", "Cycle", "Spiral", "Ascent", "Descent",
            "Climb", "Fall", "Rise", "Set", "Expand", "Contract", "Grow", "Shrink", "Develop", "Decline",
            "Bloom", "Wither", "Sprout", "Harvest", "Sow", "Reap", "Plant", "Root", "Branch", "Leaf",
            "Fruit", "Seed", "Soil", "Ground", "Foundation", "Structure", "Building", "Construction", "Destruction", "Creation",
            "Preservation", "Conservation", "Restoration", "Reformation", "Transformation", "Conversion", "Adaptation", "Adoption", "Acceptance", "Rejection",
            "Welcome", "Farewell", "Hello", "Goodbye", "Parting", "Reunion", "Return", "Departure", "Journey", "Voyage",
            "Expedition", "Exploration", "Adventure", "Quest", "Search", "Find", "Lose", "Seek", "Hide", "Discover",
            "Reveal", "Conceal", "Expose", "Cover", "Open", "Close", "Begin", "Complete", "Finish", "Start",
            "Continue", "Persist", "Endure", "Last", "Permanent", "Temporary", "Eternal", "Momentary", "Infinite", "Finite",
            "Limit", "Boundary", "Border", "Edge", "Center", "Middle", "Core", "Heart", "Soul", "Spirit",
            "Mind", "Body", "Thought", "Emotion", "Feeling", "Sensation", "Perception", "Consciousness", "Awareness", "Attention",
            "Intention", "Purpose", "Meaning", "Significance", "Value", "Worth", "Price", "Cost", "Benefit", "Loss",
            "Gain", "Profit", "Debt", "Credit", "Asset", "Liability", "Wealth", "Poverty", "Richness", "Poorness",
            "Abundance", "Scarcity", "Plenty", "Lack", "Excess", "Deficiency", "Fullness", "Emptiness", "Presence", "Absence"
        ]

        let koreanPool = [
            "봄", "여름", "가을", "겨울", "여정", "추억", "꿈", "희망", "성찰", "기쁨",
            "도전", "성장", "평화", "모험", "변화", "지혜", "감사", "경이로움", "아침", "저녁",
            "비", "햇살", "바다", "산", "숲", "강", "별", "달", "태양", "구름",
            "무지개", "천둥", "안개", "서리", "눈꽃", "바람", "파도", "노을", "새벽", "황혼",
            "사랑", "우정", "가족", "집", "만남", "이별", "기다림", "그리움", "행복", "슬픔",
            "용기", "결심", "믿음", "용서", "격려", "위로", "설렘", "소망", "인연", "인생",
            "여행", "독서", "음악", "요리", "산책", "운동", "창작", "그림", "사진", "일기",
            "커피", "차", "꽃", "나무", "새", "고양이", "강아지", "책", "편지", "선물",
            "시간", "순간", "기회", "선택", "후회", "반성", "깨달음", "명상", "집중",
            "목표", "계획", "실천", "노력", "인내", "열정", "포기", "도약", "전환", "재시작",
            "진실", "거짓", "선", "악", "아름다움", "추함", "강함", "약함", "시작", "끝",
            "원인", "결과", "운명", "우연", "필연", "자유", "속박", "평등", "차이", "통합",
            "발견", "탐구", "질문", "답", "비밀", "상상", "현실", "과거", "현재", "미래",
            "젊음", "노년", "건강", "상처", "치유", "평온", "혼란", "질서", "규칙", "예외",
            "전통", "혁신", "보수", "진보", "조화", "균형", "성취", "성공", "실패", "교훈",
            "배움", "가르침", "스승", "제자", "리더", "추종", "협력", "경쟁", "승리", "패배",
            "즐거움", "재미", "유쾌", "행운", "불운", "위기", "기회", "극복",
            "휴식", "여유", "바쁨", "쉼", "고요", "소음", "적막", "활기", "생기", "에너지",
            "빛", "어둠", "그림자", "형상", "색채", "선", "면", "입체", "공간",
            "속도", "거리", "방향", "목적지", "출발", "도착", "경유", "정차", "직행", "환승",
            "온도", "습도", "날씨", "기후", "환경", "생태", "자연", "인공", "도시", "시골",
            "한가로움", "적적함", "외로움", "함께함", "동행", "나홀로", "고독", "외톨이", "공동체",
            "소속", "정체성", "개성", "특성", "공통점", "차이점", "유사", "상이", "동일", "다름",
            "전체", "부분", "포함", "배제", "내부", "외부", "표면", "깊이", "넓이", "높이",
            "무게", "밀도", "질량", "부피", "차원", "세계", "우주", "은하", "태양계", "지구",
            "대륙", "섬", "반도", "해협", "만", "곶", "산맥", "평원", "고원", "분지",
            "협곡", "동굴", "폭포", "온천", "화산", "지진", "해일", "태풍", "출생", "죽음",
            "환생", "부활", "변태", "진화", "혁명", "순환", "나선", "상승", "하객", "오르기",
            "내리기", "일출", "일몰", "확장", "수축", "성장", "쇠퇴", "발전", "퇴화", "개화",
            "만개", "시들음", "싹", "수확", "파종", "거두기", "심기", "뿌리", "가지", "잎",
            "열매", "씨앗", "흙", "땅", "기초", "구조", "건설", "파괴", "보존", "보호",
            "회복", "개혁", "변형", "전환", "적응", "채택", "수용", "거부", "거절",
            "환영", "작별", "인사", "안녕", "떠남", "귀환", "귀가", "출발", "탐험", "항해",
            "원정", "탐사", "탐구", "탐색", "찾기", "발견", "발굴", "노출", "숨기", "가리기",
            "열기", "닫기", "시작하기", "완료", "마무리", "계속", "지속", "끝까지", "영원", "잠시",
            "무한", "유한", "한계", "경계", "가장자리", "중심", "중앙", "핵심", "심장", "영혼",
            "정신", "육체", "생각", "감정", "느낌", "감각", "지각", "의식", "인식", "주의",
            "의도", "목적", "의미", "중요성", "가치", "값", "대가", "비용", "이득", "손실",
            "획득", "이익", "빚", "신용", "자산", "부채", "부", "가난", "부유", "빈곤",
            "풍요", "부족", "흉작", "공허", "존재", "부재", "탄생", "죽음", "생명", "운명"
        ]

        let safeIndex = stableHash % koreanPool.count
        return language == .korean ? koreanPool[safeIndex] : englishPool[safeIndex % englishPool.count]
    }

    /// Get display keyword for a date - Firestore first, then fallback to hash
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
