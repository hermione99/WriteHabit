import SwiftUI
import FirebaseAuth

struct WritingChallengesView: View {
    @State private var userChallenges: [UserChallenge] = []
    @State private var essays: [Essay] = []
    @State private var isLoading = true
    @State private var showingCelebration = false
    @State private var completedChallenge: Challenge?
    
    // All available challenges
    let allChallenges: [Challenge] = [
        Challenge(
            id: "first_essay",
            title: "First Steps".localized,
            description: "Write your first essay".localized,
            icon: "figure.walk",
            color: .blue,
            requirement: 1,
            type: .essayCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "three_day_streak",
            title: "On a Roll".localized,
            description: "Write for 3 days in a row".localized,
            icon: "flame.fill",
            color: .orange,
            requirement: 3,
            type: .streak,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "seven_day_streak",
            title: "Week Warrior".localized,
            description: "Write for 7 days in a row".localized,
            icon: "flame.fill",
            color: .red,
            requirement: 7,
            type: .streak,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "thirty_day_streak",
            title: "Month Master".localized,
            description: "Write for 30 days in a row".localized,
            icon: "crown.fill",
            color: .purple,
            requirement: 30,
            type: .streak,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "word_1000",
            title: "Word Builder".localized,
            description: "Write 1,000 words total".localized,
            icon: "textformat",
            color: .green,
            requirement: 1000,
            type: .wordCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "word_10000",
            title: "Word Smith".localized,
            description: "Write 10,000 words total".localized,
            icon: "textformat",
            color: .indigo,
            requirement: 10000,
            type: .wordCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "word_50000",
            title: "Word Master".localized,
            description: "Write 50,000 words total".localized,
            icon: "textformat",
            color: .pink,
            requirement: 50000,
            type: .wordCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "ten_essays",
            title: "Prolific Writer".localized,
            description: "Write 10 essays".localized,
            icon: "doc.text.fill",
            color: .cyan,
            requirement: 10,
            type: .essayCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "fifty_essays",
            title: "Essay Machine".localized,
            description: "Write 50 essays".localized,
            icon: "doc.text.fill",
            color: .mint,
            requirement: 50,
            type: .essayCount,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "public_first",
            title: "Going Public".localized,
            description: "Publish your first public essay".localized,
            icon: "globe",
            color: .blue,
            requirement: 1,
            type: .publicEssays,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "public_ten",
            title: "Community Contributor".localized,
            description: "Publish 10 public essays".localized,
            icon: "globe",
            color: .teal,
            requirement: 10,
            type: .publicEssays,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "morning_writer",
            title: "Early Bird".localized,
            description: "Write before 9 AM".localized,
            icon: "sunrise.fill",
            color: .yellow,
            requirement: 1,
            type: .morningWriting,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "night_owl",
            title: "Night Owl".localized,
            description: "Write after 10 PM".localized,
            icon: "moon.fill",
            color: .indigo,
            requirement: 1,
            type: .nightWriting,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        // MARK: - Punch Card Challenges
        Challenge(
            id: "punch_first",
            title: "First Punch".localized,
            description: "Complete your first 30-day punch card".localized,
            icon: "ticket.fill",
            color: .orange,
            requirement: 30,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "punch_pro",
            title: "Punch Card Pro".localized,
            description: "Complete your second 30-day punch card (60 days total)".localized,
            icon: "ticket.fill",
            color: .red,
            requirement: 60,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "century_writer",
            title: "Century Writer".localized,
            description: "Write for 100 days straight".localized,
            icon: "100.circle.fill",
            color: .purple,
            requirement: 100,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "punch_master",
            title: "Punch Card Master".localized,
            description: "Complete 5 punch cards (150 days total)".localized,
            icon: "crown.fill",
            color: .pink,
            requirement: 150,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "double_century",
            title: "Double Century".localized,
            description: "Write for 200 days straight".localized,
            icon: "200.circle.fill",
            color: .indigo,
            requirement: 200,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "punch_legend",
            title: "Punch Card Legend".localized,
            description: "Complete 10 punch cards (300 days total)".localized,
            icon: "star.fill",
            color: .yellow,
            requirement: 300,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        ),
        Challenge(
            id: "yearly_writer",
            title: "Yearly Writer".localized,
            description: "Write every day for a full year (365 days)".localized,
            icon: "calendar.badge.checkmark",
            color: .green,
            requirement: 365,
            type: .punchCard,
            maxLevel: 0,
            requirementMultiplier: 1
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else {
                        // Sort challenges: active first, completed last
                            let sortedChallenges = allChallenges.sorted { challenge1, challenge2 in
                                let uc1 = userChallenges.first { $0.challengeId == challenge1.id }
                                let uc2 = userChallenges.first { $0.challengeId == challenge2.id }
                                let completed1 = uc1?.isCompleted ?? false
                                let completed2 = uc2?.isCompleted ?? false
                                return completed1 == completed2 ? true : !completed1
                            }
                            
                            // Active challenges
                            LazyVStack(spacing: 12) {
                                ForEach(sortedChallenges) { challenge in
                                    let userChallenge = userChallenges.first { $0.challengeId == challenge.id }
                                    let currentProgress = calculateProgress(for: challenge)
                                    let isCompleted = userChallenge?.isCompleted ?? (currentProgress >= challenge.requirement)
                                    ChallengeCard(
                                        challenge: challenge,
                                        progress: currentProgress,
                                        isCompleted: isCompleted
                                    )
                                    .opacity(isCompleted ? 0.7 : 1.0)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Challenges".localized)
            .overlay {
                if showingCelebration, let challenge = completedChallenge {
                    CelebrationView(challenge: challenge) {
                        withAnimation {
                            showingCelebration = false
                            completedChallenge = nil
                        }
                    }
                }
            }
        }
        .task {
            await loadChallenges()
        }
    }
    
    private func loadChallenges() async {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            // Load user's essays
            essays = try await FirebaseService.shared.getUserEssays(userId: userId)
            print("[DEBUG] Loaded \(essays.count) essays")
            
            // Load or create user challenges
            userChallenges = try await FirebaseService.shared.getUserChallenges(userId: userId)
            print("[DEBUG] Loaded \(userChallenges.count) user challenges")
            
            // Check for newly completed challenges
            await checkCompletedChallenges()
            
            // Print progress for debugging
            for challenge in allChallenges {
                let progress = calculateProgress(for: challenge)
                print("[DEBUG] Challenge '\(challenge.title)': progress \(progress)/\(challenge.requirement)")
            }
            
        } catch {
            print("Error loading challenges: \(error)")
        }
        
        isLoading = false
    }
    
    private func checkCompletedChallenges() async {
        for challenge in allChallenges {
            let progress = calculateProgress(for: challenge)
            let isCompleted = progress >= challenge.requirement
            
            if let userChallenge = userChallenges.first(where: { $0.challengeId == challenge.id }) {
                // Check if just completed
                if isCompleted && !userChallenge.isCompleted {
                    // Mark as completed
                    try? await FirebaseService.shared.completeChallenge(
                        userId: Auth.auth().currentUser?.uid ?? "",
                        challengeId: challenge.id
                    )
                    
                    // Show celebration
                    await MainActor.run {
                        completedChallenge = challenge
                        showingCelebration = true
                    }
                }
            } else {
                // Create new user challenge
                let newChallenge = UserChallenge(
                    id: nil,
                    userId: Auth.auth().currentUser?.uid ?? "",
                    challengeId: challenge.id,
                    progress: progress,
                    isCompleted: isCompleted,
                    completedAt: isCompleted ? Date() : nil
                )
                
                try? await FirebaseService.shared.saveUserChallenge(newChallenge)
                
                if isCompleted {
                    await MainActor.run {
                        completedChallenge = challenge
                        showingCelebration = true
                    }
                }
            }
        }
    }
    
    private func calculateProgress(for challenge: Challenge) -> Int {
        switch challenge.type {
        case .essayCount:
            return essays.count
            
        case .streak:
            return calculateCurrentStreak()
            
        case .wordCount:
            return essays.reduce(0) { $0 + $1.content.filter { !$0.isWhitespace }.count }
            
        case .publicEssays:
            return essays.filter { $0.isPublic }.count
            
        case .morningWriting:
            let calendar = Calendar.current
            return essays.contains { essay in
                let hour = calendar.component(.hour, from: essay.createdAt)
                return hour < 9
            } ? 1 : 0
            
        case .nightWriting:
            let calendar = Calendar.current
            return essays.contains { essay in
                let hour = calendar.component(.hour, from: essay.createdAt)
                return hour >= 22
            } ? 1 : 0
            
        case .punchCard:
            // 일일 키워드 에세이의 고유 일수 카운트
            let calendar = Calendar.current
            let dailyPromptEssays = calculateDailyPromptEssays()
            let uniqueDays = Set(dailyPromptEssays.map { calendar.startOfDay(for: $0.createdAt) })
            return uniqueDays.count
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let sortedDays = Set(essays.map { calendar.startOfDay(for: $0.createdAt) }).sorted(by: >)
        
        guard !sortedDays.isEmpty else { return 0 }
        
        var streak = 1
        var previousDay = sortedDays[0]
        
        for day in sortedDays.dropFirst() {
            if calendar.isDate(day, equalTo: calendar.date(byAdding: .day, value: -1, to: previousDay)!, toGranularity: .day) {
                streak += 1
                previousDay = day
            } else {
                break
            }
        }
        
        return streak
    }
    
    // Total unique writing days (for Punch Card challenges)
    private func calculateDailyPromptEssays() -> [Essay] {
        let calendar = Calendar.current
        return essays.filter { essay in
            guard essay.deletedAt == nil else { return false }
            
            let essayDay = calendar.startOfDay(for: essay.createdAt)
            let components = calendar.dateComponents([.year, .month, .day], from: essayDay)
            let year = components.year ?? 0
            let month = components.month ?? 0
            let day = components.day ?? 0
            let stableHash = ((year * 365 + month * 31 + day) * 9301 + 49297) % 233280
            let poolIndex = stableHash % 100
            let koreanPool = [
                "봄", "여정", "추억", "꿈", "희망", "성찰", "기쁨", "도전", "성장", "평화",
                "모험", "변화", "지혜", "감사", "경이로움", "아침", "저녁", "비", "햇살", "바다",
                "산", "숲", "강", "별", "달", "집", "가족", "우정", "사랑", "용기"
            ]
            let expectedKeyword = koreanPool[poolIndex % koreanPool.count]
            return essay.keyword == expectedKeyword
        }
    }
}

// MARK: - Passport Stamp

struct StampView: View {
    var body: some View {
        ZStack {
            // Everything rotates together
            Group {
                // Jagged outer ring
                JaggedCircle()
                    .stroke(Color(hex: "4A5A30"), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Inner thin ring
                Circle()
                    .stroke(Color(hex: "4A5A30").opacity(0.6), lineWidth: 1)
                    .frame(width: 44, height: 44)
                
                // Top stars - larger and more visible
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                }
                .offset(y: -12)
                
                // Bottom stars - larger and more visible
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "4A5A30"))
                }
                .offset(y: 12)
                
                // Diagonal ribbon banner - longer to extend beyond circle
                ZStack {
                    BannerShape()
                        .fill(Color(hex: "4A5A30"))
                        .frame(width: 72, height: 16)
                    
                    Text("COMPLETE")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(.white)
                }
            }
            .rotationEffect(.degrees(-12))
        }
    }
}

// Banner shape with notched ends (fits within circle)
struct BannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let notchDepth: CGFloat = 4
        let notchWidth: CGFloat = 5
        
        // Start from top-left (after notch)
        path.move(to: CGPoint(x: notchWidth, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.width - notchWidth, y: 0))
        
        // Top-right notch (pointing inward)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width - notchWidth, y: rect.height))
        
        // Bottom edge
        path.addLine(to: CGPoint(x: notchWidth, y: rect.height))
        
        // Bottom-left notch (pointing inward)
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: notchWidth, y: 0))
        
        path.closeSubpath()
        return path
    }
}

// Jagged circle for distressed stamp edge
struct JaggedCircle: Shape {
    var points: Int = 32
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * 2 * .pi
            let isJagged = i % 2 == 0
            let r = isJagged ? radius * 0.92 : radius
            
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Stamp Border

// Wavy stamp border shape
struct StampBorder: Shape {
    var teeth: Int = 20
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<teeth {
            let angle = (Double(i) / Double(teeth)) * 2 * .pi
            let innerRadius = radius * 0.85
            let outerRadius = radius
            
            let innerX = center.x + cos(angle) * innerRadius
            let innerY = center.y + sin(angle) * innerRadius
            let outerX = center.x + cos(angle) * outerRadius
            let outerY = center.y + sin(angle) * outerRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: innerX, y: innerY))
            }
            
            path.addLine(to: CGPoint(x: outerX, y: outerY))
            
            let nextAngle = (Double((i + 1) % teeth) / Double(teeth)) * 2 * .pi
            let nextInnerX = center.x + cos(nextAngle) * innerRadius
            let nextInnerY = center.y + sin(nextAngle) * innerRadius
            path.addLine(to: CGPoint(x: nextInnerX, y: nextInnerY))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: Challenge
    let progress: Int
    let isCompleted: Bool
    
    var percentage: Double {
        min(Double(progress) / Double(challenge.requirement), 1.0)
    }
    
    // Header color based on status
    var headerColor: Color {
        if isCompleted {
            return Color(hex: "4A5A30") // Moss
        } else {
            switch challenge.type {
            case .essayCount: return Color(hex: "0D244D") // Indigo
            case .streak: return Color(hex: "852E47") // Ruby
            case .wordCount: return Color(hex: "C2441C") // Burnt
            case .publicEssays: return Color(hex: "4A5A30") // Moss
            case .morningWriting: return Color(hex: "D4A017") // Gold
            case .nightWriting: return Color(hex: "2C3E50") // Midnight
            case .punchCard: return Color(hex: "C2441C") // Burnt Orange
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - main content
            VStack(alignment: .leading, spacing: 0) {
                // Top colored header band
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: challenge.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(challenge.type.displayName.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(headerColor)
                
                // Content area
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(challenge.description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Progress label - torn paper style
                        HStack(spacing: 3) {
                            Text("\(progress)")
                                .font(.system(size: 12, weight: .bold))
                            Text("/")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("\(challenge.requirement)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "FDFBF7"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(hex: "B8B3A8"), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Full-width progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 5)
                            Rectangle()
                                .fill(isCompleted ? Color(hex: "4A5A30") : headerColor)
                                .frame(width: geometry.size.width * CGFloat(percentage), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(14)
                
                // Bottom info bar
                HStack {
                    Text(isCompleted ? "VALIDATED" : "ACTIVE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundColor(isCompleted ? Color(hex: "4A5A30") : Color(hex: "666666"))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "F0EBE3"))
            }
            .background(Color(hex: "FDFBF7"))
            
            // Perforated line
            PerforatedLine()
                .frame(width: 16)
                .background(Color(hex: "F5F0E8"))
            
            // Right side - stamp area
            ZStack {
                Color(hex: "FAF8F3")
                
                if isCompleted {
                    // Passport stamp for completed
                    StampView()
                        .rotationEffect(.degrees(-8))
                } else {
                    // Progress circle for incomplete
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "E8E0D0"), lineWidth: 3)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(percentage))
                                .stroke(headerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(percentage * 100))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(headerColor)
                        }
                        
                        Text("\(progress)/\(challenge.requirement)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 76)
        }
        .background(Color(hex: "FDFBF7"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "D4CFC3"), lineWidth: 1)
        )
    }
}

// MARK: - Perforated Line

struct PerforatedLine: View {
    var body: some View {
        GeometryReader { geometry in
            let dotCount = Int(geometry.size.height / 10)
            VStack(spacing: 0) {
                ForEach(0..<dotCount, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "B8B3A8"))
                        .frame(width: 2, height: 2)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 8)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Celebration View

struct CelebrationView: View {
    let challenge: Challenge
    let onComplete: () -> Void
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onComplete()
                }
            
            VStack(spacing: 24) {
                // Animated icon
                Image(systemName: challenge.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(challenge.color)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .rotationEffect(.degrees(showContent ? 0 : -180))
                
                VStack(spacing: 8) {
                    Text("Challenge Complete!".localized)
                        .font(.title.weight(.bold))
                    
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(challenge.color)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    onComplete()
                } label: {
                    Text("Awesome!".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(challenge.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(Color(hex: "FDFBF7"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

#Preview {
    WritingChallengesView()
}
