import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    let userId: String? // nil = current user's profile
    @State private var essays: [Essay] = []
    @State private var isLoading = false
    @State private var showingSignOutConfirmation = false
    @State private var showingSettings = false
    @State private var showingAllEssays = false
    @State private var showingEditProfile = false
    @State private var showingArchive = false
    @State private var showingDrafts = false
    @State private var showingAnalytics = false
    @State private var showingChallenges = false
    @State private var showingBookExport = false
    @State private var showingFriends = false
    @State private var friendCount = 0
    @State private var userProfile: UserProfile?
    @State private var isFollowing = false
    @State private var isUpdatingFollow = false
    @StateObject private var languageManager = LanguageManager.shared
    
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
                    StatsRow()
                    
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
                        .padding(.horizontal)
                        
                        Button {
                            showingDrafts = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.clock")
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
                        .padding(.horizontal)
                        
                        Button {
                            showingAnalytics = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
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
                        .padding(.horizontal)
                        
                        Button {
                            showingChallenges = true
                        } label: {
                            HStack {
                                Image(systemName: "trophy.fill")
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
                        .padding(.horizontal)
                        
                        Button {
                            showingFriends = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("Friends".localized)
                                Spacer()
                                if friendCount > 0 {
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
                        .padding(.horizontal)
                        
                        Button {
                            showingBookExport = true
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill")
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
                        .padding(.horizontal)
                        
                        // Sign out button
                        Button {
                            showingSignOutConfirmation = true
                        } label: {
                            Text("Sign Out".localized)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        .padding(.top, 20)
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
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
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
        }
        .task {
            await loadUserProfile()
            await loadFriendCount()
            await loadUserEssays()
        }
        .alert("Sign Out?".localized, isPresented: $showingSignOutConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Sign Out".localized, role: .destructive) {
                signOut()
            }
        }
    }
    
    private func loadUserProfile() async {
        guard !profileUserId.isEmpty else { return }
        do {
            userProfile = try await FirebaseService.shared.getUserProfile(userId: profileUserId)
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
        } catch {
            print("Error loading friend count: \(error)")
        }
    }
    
    private func loadUserEssays() async {
        guard !profileUserId.isEmpty else { return }
        isLoading = true
        do {
            essays = try await FirebaseService.shared.getUserEssays(userId: profileUserId)
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
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
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
                    .background(isFollowing ? Color.secondary.opacity(0.2) : Color.blue)
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
                                .foregroundStyle(.blue)
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
                                .foregroundStyle(.black)
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
    var body: some View {
        HStack(spacing: 40) {
            ProfileStatView(value: "47", label: "Essays".localized)
            ProfileStatView(value: "1.2k", label: "Likes".localized)
            ProfileStatView(value: "18", label: "Followers".localized)
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Keyword emoji badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
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
    ProfileView(userId: nil)
}
