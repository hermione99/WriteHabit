import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    let userId: String? // nil = current user's profile
    var onSignOut: (() -> Void)? = nil // Callback when user signs out
    @State private var essays: [Essay] = []
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var showingAllEssays = false
    @State private var showingEditProfile = false
    @State private var showingArchive = false
    @State private var showingDrafts = false
    @State private var showingAnalytics = false
    @State private var showingChallenges = false
    @State private var showingBookExport = false
    @State private var showingFriends = false
    @State private var showingNotifications = false
    @State private var friendCount = 0
    @State private var unreadNotificationCount = 0
    @StateObject private var friendsService = FriendsService.shared
    @State private var userProfile: UserProfile?
    @State private var isFollowing = false
    @State private var isUpdatingFollow = false
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var isOwnProfile: Bool {
        guard let targetId = userId else { return true }
        guard let currentId = Auth.auth().currentUser?.uid else { return false }
        return targetId == currentId
    }
    
    var profileUserId: String {
        userId ?? Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beige background
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header with follow button for other users
                        ProfileHeader(profile: userProfile, isOwnProfile: isOwnProfile, isFollowing: $isFollowing, onFollowTapped: {
                            Task { await toggleFollow() }
                        })
                        
                        // Stats row - exclude deleted essays
                        let nonDeletedEssays = essays.filter { $0.deletedAt == nil }
                        StatsRow(essayCount: nonDeletedEssays.count, 
                                 totalLikes: nonDeletedEssays.reduce(0) { $0 + $1.likesCount },
                                 friends: friendCount,
                                 followers: 0) // TODO: Load actual followers count from Firebase
                        
                        // Weekly Statistics Section
                        WeeklyStatsView(essays: essays, onShowAllTapped: {
                            showingAnalytics = true
                        })
                        
                        Divider()
                            .background(Color(hex: "0D244D").opacity(0.1))
                            .padding(.horizontal)
                        
                        // Menu buttons (only for own profile)
                        if isOwnProfile {
                            Button {
                                showingArchive = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Text("Writing Archive".localized)
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                }
                                .font(.subheadline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FDFBF7"))
                                        .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .tint(.primary)
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            Button {
                                showingDrafts = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.badge.clock")
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Text("Drafts".localized)
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                }
                                .font(.subheadline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FDFBF7"))
                                        .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .tint(.primary)
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            Button {
                                showingChallenges = true
                            } label: {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Text("Challenges".localized)
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                }
                                .font(.subheadline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FDFBF7"))
                                        .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .tint(.primary)
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            Button {
                                showingFriends = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Text("Friends".localized)
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Spacer()
                                    
                                    // Show pending requests badge
                                    if friendsService.pendingRequests.count > 0 {
                                        Text("\(friendsService.pendingRequests.count)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Color(hex: "C2441C"))
                                            .clipShape(Circle())
                                    } else if friendCount > 0 {
                                        Text("\(friendCount)")
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                }
                                .font(.subheadline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FDFBF7"))
                                        .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .tint(.primary)
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            Button {
                                showingBookExport = true
                            } label: {
                                HStack {
                                    Image(systemName: "book.closed.fill")
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Text("Create Book".localized)
                                        .foregroundStyle(Color(hex: "0D244D"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "0D244D").opacity(0.5))
                                }
                                .font(.subheadline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FDFBF7"))
                                        .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .tint(.primary)
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationTitle(isOwnProfile ? "Profile".localized : "User Profile".localized)
            .toolbar {
                if isOwnProfile {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Image(systemName: "pencil.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 20) {
                            // Notification bell
                            Button {
                                showingNotifications = true
                            } label: {
                                ZStack {
                                    Image(systemName: "bell")
                                        .font(.system(size: 18))
                                    if unreadNotificationCount > 0 {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Text("\(unreadNotificationCount)")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 8, y: -8)
                                    }
                                }
                            }
                            
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile, onDismiss: {
                // Refresh profile when EditProfile sheet dismisses
                Task {
                    await loadUserProfile()
                }
            }) {
                EditProfileView()
            }
            .sheet(isPresented: $showingAllEssays) {
                AllEssaysView()
            }
            .sheet(isPresented: $showingArchive) {
                KeywordArchiveView()
            }
            .sheet(isPresented: $showingDrafts) {
                DraftsView()
            }
            .sheet(isPresented: $showingAnalytics) {
                WritingAnalyticsView()
            }
            .sheet(isPresented: $showingChallenges) {
                WritingChallengesView()
            }
            .sheet(isPresented: $showingFriends) {
                FriendsView()
            }
            .sheet(isPresented: $showingBookExport) {
                BookExportView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
        }
        .task {
            await loadUserProfile()
            await loadFriendCount()
            await loadUserEssays()
            await loadUnreadNotificationCount()
            friendsService.startListeningForRequests()
            startNotificationListener()
        }
        .onAppear {
            // Refresh profile when returning from EditProfile
            Task {
                await loadUserProfile()
            }
        }
    }
    
    private func loadUnreadNotificationCount() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .count.getAggregation(source: .server)
            
            await MainActor.run {
                unreadNotificationCount = Int(snapshot.count)
            }
        } catch {
            print("Error loading unread count: \(error)")
        }
    }
    
    private func startNotificationListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error listening to notifications: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                Task { @MainActor in
                    self.unreadNotificationCount = snapshot.documents.count
                }
            }
    }
    
    private func loadUserProfile() async {
        guard !profileUserId.isEmpty else { return }
        do {
            userProfile = try await FirebaseService.shared.getUserProfile(userId: profileUserId)
            print("DEBUG: Profile loaded, photoUrl: \(userProfile?.profilePhotoUrl?.prefix(30) ?? "nil")")
            if !isOwnProfile {
                await checkIfFollowing()
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func loadFriendCount() async {
        guard isOwnProfile else { return }
        do {
            let friends = try await FriendsService.shared.getFriends()
            friendCount = friends.count
            print("[DEBUG] Loaded \(friendCount) friends")
        } catch {
            print("Error loading friend count: \(error)")
        }
    }
    
    private func loadUserEssays() async {
        guard !profileUserId.isEmpty else { return }
        isLoading = true
        do {
            essays = try await FirebaseService.shared.getUserEssays(userId: profileUserId)
            print("[DEBUG] Loaded \(essays.count) essays")
            let totalLikes = essays.reduce(0) { $0 + $1.likesCount }
            print("[DEBUG] Total likes: \(totalLikes)")
        } catch {
            print("Error loading essays: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func checkIfFollowing() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        do {
            isFollowing = try await FirebaseService.shared.isFollowing(
                currentUserId: currentUserId,
                targetUserId: profileUserId
            )
        } catch {
            print("Error checking follow status: \(error)")
        }
    }
    
    private func toggleFollow() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isUpdatingFollow = true
        do {
            if isFollowing {
                try await FirebaseService.shared.unfollowUser(
                    currentUserId: currentUserId,
                    targetUserId: profileUserId
                )
            } else {
                try await FirebaseService.shared.followUser(
                    currentUserId: currentUserId,
                    targetUserId: profileUserId
                )
            }
            isFollowing.toggle()
        } catch {
            print("Error toggling follow: \(error)")
        }
        isUpdatingFollow = false
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Small delay to let UI dismiss alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.onSignOut?()
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ProfileHeader: View {
    let profile: UserProfile?
    let isOwnProfile: Bool
    @Binding var isFollowing: Bool
    let onFollowTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar with profile photo
            if let profile = profile {
                AvatarView(url: profile.profilePhotoUrl, size: 100, userId: profile.userId)
                    .onAppear {
                        print("ProfileHeader: AvatarView appeared, photoUrl: \(profile.profilePhotoUrl?.prefix(30) ?? "nil")")
                    }
            } else {
                Circle()
                    .fill(Color(hex: "0D244D").opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "0D244D"))
                    }
            }
            
            VStack(spacing: 4) {
                Text(profile?.displayName ?? "Writer".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "0D244D"))
                
                if let username = profile?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "0D244D").opacity(0.6))
                }
            }
            
            // Follow Button (only for other users' profiles)
            if !isOwnProfile {
                Button(action: onFollowTapped) {
                    HStack {
                        Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                        Text(isFollowing ? "Following".localized : "Follow".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(isFollowing ? Color(hex: "0D244D").opacity(0.2) : Color(hex: "0D244D"))
                    .foregroundColor(isFollowing ? Color(hex: "0D244D") : Color.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            
            // Social Links
            if let profile = profile, hasSocialLinks(profile) {
                HStack(spacing: 16) {
                    if let blog = profile.blogUrl, !blog.isEmpty {
                        Link(destination: URL(string: blog)!) {
                            Image(systemName: "link.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "0D244D"))
                        }
                    }
                    if let brunch = profile.brunchUrl, !brunch.isEmpty {
                        Link(destination: URL(string: brunch)!) {
                            Image(systemName: "book.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "4A5A30"))
                        }
                    }
                    if let instagram = profile.instagramUrl, !instagram.isEmpty {
                        Link(destination: URL(string: instagram)!) {
                            Image(systemName: "camera.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.pink)
                        }
                    }
                    if let twitter = profile.twitterUrl, !twitter.isEmpty {
                        Link(destination: URL(string: twitter)!) {
                            Image(systemName: "bird.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)
                        }
                    }
                    if let threads = profile.threadsUrl, !threads.isEmpty {
                        Link(destination: URL(string: threads)!) {
                            Image(systemName: "at.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func hasSocialLinks(_ profile: UserProfile) -> Bool {
        return !(profile.blogUrl?.isEmpty ?? true)
            || !(profile.brunchUrl?.isEmpty ?? true)
            || !(profile.instagramUrl?.isEmpty ?? true)
            || !(profile.twitterUrl?.isEmpty ?? true)
            || !(profile.threadsUrl?.isEmpty ?? true)
    }
}

struct StatsRow: View {
    let essayCount: Int
    let totalLikes: Int
    let friends: Int
    let followers: Int
    
    var body: some View {
        HStack(spacing: 30) {
            ProfileStatView(value: "\(essayCount)", label: "Essays".localized)
            ProfileStatView(value: formatLikes(totalLikes), label: "Likes".localized)
            ProfileStatView(value: "\(friends)", label: "Friends".localized)
            ProfileStatView(value: "\(followers)", label: "Followers".localized)
        }
    }
    
    func formatLikes(_ likes: Int) -> String {
        if likes >= 1000 {
            return String(format: "%.1fk", Double(likes) / 1000.0)
        } else {
            return "\(likes)"
        }
    }
}

struct ProfileStatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "0D244D"))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color(hex: "0D244D").opacity(0.6))
        }
    }
}

struct MyEssayRow: View {
    let essay: Essay
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Keyword emoji badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.accent.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(KeywordEmojiService.shared.emojiForKeyword(essay.keyword))
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(timeAgo(from: essay.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private func timeAgo(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Weekly Statistics View

struct WeeklyStatsView: View {
    let essays: [Essay]
    let onShowAllTapped: () -> Void
    
    private var weeklyData: [(day: String, count: Int, words: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [(String, Int, Int)] = []
        
        // Get last 7 days (Monday to Sunday or just last 7 days)
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayEssays = essays.filter { essay in
                // Filter out deleted essays
                guard essay.deletedAt == nil else { return false }
                return calendar.isDate(essay.createdAt, inSameDayAs: date)
            }
            let count = dayEssays.count
            let words = dayEssays.reduce(0) { $0 + $1.wordCount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayString = formatter.string(from: date).uppercased()
            
            data.append((dayString, count, words))
        }
        return data
    }
    
    private var totalWordsThisWeek: Int {
        weeklyData.reduce(0) { $0 + $1.words }
    }
    
    private var totalEssaysThisWeek: Int {
        weeklyData.reduce(0) { $0 + $1.count }
    }
    
    private var maxCount: Int {
        max(weeklyData.map { $0.count }.max() ?? 1, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week".localized)
                        .font(.headline)
                        .foregroundStyle(Color(hex: "0D244D"))
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("\(totalEssaysThisWeek)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "0D244D"))
                            Text("essays".localized)
                                .font(.caption)
                                .foregroundStyle(Color(hex: "0D244D").opacity(0.6))
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(totalWordsThisWeek)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "0D244D"))
                            Text("words".localized)
                                .font(.caption)
                                .foregroundStyle(Color(hex: "0D244D").opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Show all button
                Button {
                    onShowAllTapped()
                } label: {
                    HStack(spacing: 4) {
                        Text("Show all".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: "0D244D"))
                }
            }
            .padding(.horizontal)
            
            // Bar Chart
            HStack(spacing: 12) {
                ForEach(weeklyData, id: \.day) { data in
                    VStack(spacing: 8) {
                        // Bar
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "0D244D").opacity(0.1))
                                .frame(width: 24, height: 60)
                            
                            if data.count > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "4A5A30")) // Moss Shadow for written
                                    .frame(width: 24, height: CGFloat(data.count) / CGFloat(maxCount) * 60)
                            }
                        }
                        
                        // Day label
                        Text(data.day)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(data.count > 0 ? Color(hex: "0D244D") : Color(hex: "0D244D").opacity(0.4))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "FDFBF7"))
                    .shadow(color: Color(hex: "0D244D").opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)
        }
    }
}

#Preview {
    ProfileView(userId: nil, onSignOut: {})
}
