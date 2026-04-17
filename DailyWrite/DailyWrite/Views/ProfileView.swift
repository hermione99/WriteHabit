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
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header with follow button for other users
                    ProfileHeader(profile: userProfile, isOwnProfile: isOwnProfile, isFollowing: isFollowing, onFollowTapped: {
                        Task { await toggleFollow() }
                    })
                    
                    // Stats row
                    StatsRow(essayCount: essays.count, 
                             totalLikes: essays.reduce(0) { $0 + $1.likesCount },
                             friends: friendCount,
                             followers: 0) // TODO: Load actual followers count from Firebase
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Essays section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(isOwnProfile ? "Your Essays".localized : "Essays".localized)
                                .font(.headline)
                            Spacer()
                            if isOwnProfile {
                                Button("See All".localized) {
                                    showingAllEssays = true
                                }
                            }
                        }
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if essays.isEmpty {
                            Text("No essays yet".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(essays.prefix(3)) { essay in
                                MyEssayRow(essay: essay)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Menu buttons (only for own profile)
                    if isOwnProfile {
                        Button {
                            showingArchive = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.primary)
                                Text("Writing Archive".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Button {
                            showingDrafts = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.clock")
                                    .foregroundStyle(.primary)
                                Text("Drafts".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Button {
                            showingAnalytics = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(.primary)
                                Text("Writing Analytics".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Button {
                            showingChallenges = true
                        } label: {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.primary)
                                Text("Challenges".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Button {
                            showingFriends = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.primary)
                                Text("Friends".localized)
                                Spacer()
                                
                                // Show pending requests badge
                                if friendsService.pendingRequests.count > 0 {
                                    Text("\(friendsService.pendingRequests.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                } else if friendCount > 0 {
                                    Text("\(friendCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Button {
                            showingBookExport = true
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(.primary)
                                Text("Create Book".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
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
                        HStack(spacing: 8) {
                            // Notification bell
                            Button {
                                showingNotifications = true
                            } label: {
                                ZStack {
                                    Image(systemName: "bell")
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
    let isFollowing: Bool
    let onFollowTapped: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
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
                    .fill(themeManager.accent.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(themeManager.accent)
                    }
            }
            
            VStack(spacing: 4) {
                Text(profile?.displayName ?? "Writer".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let username = profile?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(profile?.bio ?? "Daily writer exploring thoughts one prompt at a time.".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
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
                    .background(isFollowing ? Color.secondary.opacity(0.2) : themeManager.accent)
                    .foregroundColor(isFollowing ? .gray : .white)
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
                                .foregroundStyle(themeManager.accent)
                        }
                    }
                    if let brunch = profile.brunchUrl, !brunch.isEmpty {
                        Link(destination: URL(string: brunch)!) {
                            Image(systemName: "book.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
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
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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

#Preview {
    ProfileView(userId: nil, onSignOut: {})
}
