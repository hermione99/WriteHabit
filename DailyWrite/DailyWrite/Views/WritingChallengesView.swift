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
            type: .essayCount
        ),
        Challenge(
            id: "three_day_streak",
            title: "On a Roll".localized,
            description: "Write for 3 days in a row".localized,
            icon: "flame.fill",
            color: .orange,
            requirement: 3,
            type: .streak
        ),
        Challenge(
            id: "seven_day_streak",
            title: "Week Warrior".localized,
            description: "Write for 7 days in a row".localized,
            icon: "flame.fill",
            color: .red,
            requirement: 7,
            type: .streak
        ),
        Challenge(
            id: "thirty_day_streak",
            title: "Month Master".localized,
            description: "Write for 30 days in a row".localized,
            icon: "crown.fill",
            color: .purple,
            requirement: 30,
            type: .streak
        ),
        Challenge(
            id: "word_1000",
            title: "Word Builder".localized,
            description: "Write 1,000 words total".localized,
            icon: "textformat",
            color: .green,
            requirement: 1000,
            type: .wordCount
        ),
        Challenge(
            id: "word_10000",
            title: "Word Smith".localized,
            description: "Write 10,000 words total".localized,
            icon: "textformat",
            color: .indigo,
            requirement: 10000,
            type: .wordCount
        ),
        Challenge(
            id: "word_50000",
            title: "Word Master".localized,
            description: "Write 50,000 words total".localized,
            icon: "textformat",
            color: .pink,
            requirement: 50000,
            type: .wordCount
        ),
        Challenge(
            id: "ten_essays",
            title: "Prolific Writer".localized,
            description: "Write 10 essays".localized,
            icon: "doc.text.fill",
            color: .cyan,
            requirement: 10,
            type: .essayCount
        ),
        Challenge(
            id: "fifty_essays",
            title: "Essay Machine".localized,
            description: "Write 50 essays".localized,
            icon: "doc.text.fill",
            color: .mint,
            requirement: 50,
            type: .essayCount
        ),
        Challenge(
            id: "public_first",
            title: "Going Public".localized,
            description: "Publish your first public essay".localized,
            icon: "globe",
            color: .blue,
            requirement: 1,
            type: .publicEssays
        ),
        Challenge(
            id: "public_ten",
            title: "Community Contributor".localized,
            description: "Publish 10 public essays".localized,
            icon: "globe",
            color: .teal,
            requirement: 10,
            type: .publicEssays
        ),
        Challenge(
            id: "morning_writer",
            title: "Early Bird".localized,
            description: "Write before 9 AM".localized,
            icon: "sunrise.fill",
            color: .yellow,
            requirement: 1,
            type: .morningWriting
        ),
        Challenge(
            id: "night_owl",
            title: "Night Owl".localized,
            description: "Write after 10 PM".localized,
            icon: "moon.fill",
            color: .indigo,
            requirement: 1,
            type: .nightWriting
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Progress summary - calculate completed based on actual progress
                        let completedCount = allChallenges.filter { challenge in
                            calculateProgress(for: challenge) >= challenge.requirement
                        }.count
                        ProgressSummaryView(
                            completed: completedCount,
                            total: allChallenges.count
                        )
                        
                        // Active challenges
                        LazyVStack(spacing: 12) {
                            ForEach(allChallenges) { challenge in
                                let userChallenge = userChallenges.first { $0.challengeId == challenge.id }
                                // Calculate fresh progress from essays, not from stored value
                                let currentProgress = calculateProgress(for: challenge)
                                ChallengeCard(
                                    challenge: challenge,
                                    progress: currentProgress,
                                    isCompleted: userChallenge?.isCompleted ?? (currentProgress >= challenge.requirement)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
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
}

struct ProgressSummaryView: View {
    let completed: Int
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: percentage)
                
                VStack(spacing: 2) {
                    Text("\(completed)/\(total)")
                        .font(.title2.weight(.bold))
                    Text("Completed".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Motivational text
            if completed == 0 {
                Text("Start your first challenge!".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if completed == total {
                Text("Amazing! You've completed all challenges!".localized)
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Text("\(total - completed) more to go!".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(challenge.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundStyle(challenge.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(challenge.title)
                    .font(.headline)
                
                Text(challenge.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isCompleted ? Color.green : challenge.color)
                            .frame(width: geometry.size.width * CGFloat(percentage), height: 6)
                            .animation(.easeInOut(duration: 0.5), value: percentage)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(progress)/\(challenge.requirement)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Done!".localized)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isCompleted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
            }
        }
        .opacity(isCompleted ? 0.9 : 1.0)
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
            .background(Color(.systemBackground))
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
