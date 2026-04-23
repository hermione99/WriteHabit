import SwiftUI
import FirebaseAuth

struct PublicProfileView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var friendsService = FriendsService.shared
    @State private var userProfile: UserProfile?
    @State private var essays: [Essay] = []
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var showFollowButton = false
    @State private var selectedEssay: Essay? = nil
    @State private var showEssayDetail = false
    @State private var friendRequestSent = false
    
    private let indigoColor = Color(hex: "0D244D")
    private let creamColor = Color(hex: "F5F0E8")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cream background
                creamColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Stats
                        statsSection
                            .padding(.horizontal, 20)
                        
                        // Recent Essays
                        recentEssaysSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(indigoColor)
                    }
                }
            }
            .sheet(item: $selectedEssay) { essay in
                EssayDetailView(essay: essay)
            }
        }
        .task {
            await loadProfile()
            await loadUserEssays()
            checkIfFollowing()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image
            if let photoUrl = userProfile?.profilePhotoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(indigoColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(indigoColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(indigoColor.opacity(0.5))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(indigoColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(indigoColor.opacity(0.5))
                    )
            }
            
            // Name
            Text(userProfile?.displayName ?? "Unknown")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(indigoColor)
            
            // Username
            if let username = userProfile?.username {
                Text("@\(username)")
                    .font(.system(size: 15))
                    .foregroundStyle(indigoColor.opacity(0.6))
            }
            
            // Follow & Add Friend Buttons (only if not own profile)
            if showFollowButton {
                HStack(spacing: 12) {
                    // Follow Button
                    Button(action: {
                        Task { await toggleFollow() }
                    }) {
                        Text(isFollowing ? "Following".localized : "Follow".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isFollowing ? indigoColor : .white)
                            .frame(width: 100, height: 36)
                            .background(isFollowing ? creamColor : indigoColor)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(indigoColor, lineWidth: isFollowing ? 1 : 0)
                            )
                    }
                    
                    // Add Friend Button
                    Button(action: {
                        Task { await sendFriendRequest() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: friendRequestSent ? "checkmark" : "person.badge.plus")
                                .font(.system(size: 14))
                            Text(friendRequestSent ? "요청 보냄" : "Add Friend".localized)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(width: friendRequestSent ? 100 : 120, height: 36)
                        .background(friendRequestSent ? Color.gray : Color(hex: "4a5a30"))
                        .cornerRadius(18)
                    }
                    .disabled(friendRequestSent)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(essays.filter { $0.deletedAt == nil }.count)", label: "Essays".localized)
            Divider().frame(height: 40)
            StatItem(value: "\(essays.filter { $0.deletedAt == nil }.reduce(0) { $0 + $1.likesCount })", label: "Likes".localized)
            Divider().frame(height: 40)
            StatItem(value: "\(essays.filter { $0.deletedAt == nil }.reduce(0) { $0 + $1.wordCount })", label: "Words".localized)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Essays Section
    private var recentEssaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Essays".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(indigoColor)
            
            let nonDeletedEssays = essays.filter { $0.deletedAt == nil }.prefix(5)
            
            if nonDeletedEssays.isEmpty {
                Text("No essays yet".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(indigoColor.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(nonDeletedEssays)) { essay in
                    EssayRow(essay: essay)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEssay = essay
                        }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadProfile() async {
        isLoading = true
        do {
            userProfile = try await FirebaseService.shared.getUserProfile(userId: userId)
        } catch {
            print("Error loading profile: \(error)")
        }
        isLoading = false
    }
    
    private func loadUserEssays() async {
        do {
            essays = try await FirebaseService.shared.getUserEssays(userId: userId)
        } catch {
            print("Error loading essays: \(error)")
        }
    }
    
    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard userId != currentUserId else { 
            showFollowButton = false
            return 
        }
        showFollowButton = true
        
        Task {
            do {
                isFollowing = try await FirebaseService.shared.isFollowing(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
            } catch {
                print("Error checking follow status: \(error)")
            }
        }
    }
    
    private func toggleFollow() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            if isFollowing {
                try await FirebaseService.shared.unfollowUser(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
            } else {
                try await FirebaseService.shared.followUser(
                    currentUserId: currentUserId,
                    targetUserId: userId
                )
            }
            isFollowing.toggle()
        } catch {
            print("Error toggling follow: \(error)")
        }
    }
    
    private func sendFriendRequest() async {
        do {
            try await friendsService.sendFriendRequest(to: userId)
            await MainActor.run {
                friendRequestSent = true
            }
            print("✅ Friend request sent to \(userId)")
        } catch {
            print("Error sending friend request: \(error)")
        }
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "0D244D"))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "0D244D").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Essay Row
private struct EssayRow: View {
    let essay: Essay
    private let indigoColor = Color(hex: "0D244D")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(essay.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(indigoColor)
                .lineLimit(1)
            
            Text(essay.content.prefix(100) + (essay.content.count > 100 ? "..." : ""))
                .font(.system(size: 14))
                .foregroundStyle(indigoColor.opacity(0.7))
                .lineLimit(2)
            
            HStack {
                Text(formattedDate(essay.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(indigoColor.opacity(0.5))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                    Text("\(essay.likesCount)")
                        .font(.system(size: 12))
                }
                .foregroundStyle(indigoColor.opacity(0.5))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
