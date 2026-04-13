import SwiftUI
import FirebaseAuth

struct FriendsView: View {
    @State private var friends: [UserProfile] = []
    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoading = true
    @State private var showingAddFriend = false
    @State private var searchUsername = ""
    @State private var searchResult: UserProfile?
    @State private var searchError: String?
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Pending requests section
                if !pendingRequests.isEmpty {
                    Section("Friend Requests".localized) {
                        ForEach(pendingRequests) { request in
                            FriendRequestRow(request: request) {
                                Task {
                                    await acceptRequest(request)
                                }
                            } onDecline: {
                                Task {
                                    await declineRequest(request)
                                }
                            }
                        }
                    }
                }
                
                // Friends list
                Section {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if friends.isEmpty {
                        EmptyFriendsView()
                    } else {
                        ForEach(friends) { friend in
                            FriendRow(friend: friend)
                        }
                        .onDelete(perform: deleteFriend)
                    }
                } header: {
                    Text("My Friends".localized)
                } footer: {
                    if !friends.isEmpty {
                        Text("\(friends.count) friends".localized)
                    }
                }
            }
            .navigationTitle("Friends".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendSheet()
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            async let friendsTask = FriendsService.shared.getFriends()
            async let requestsTask = FriendsService.shared.getPendingRequests()
            
            friends = try await friendsTask
            pendingRequests = try await requestsTask
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }
    
    private func acceptRequest(_ request: FriendRequest) async {
        guard let requestId = request.id else { return }
        do {
            try await FriendsService.shared.acceptFriendRequest(requestId)
            await loadData()
        } catch {
            print("Error accepting request: \(error)")
        }
    }
    
    private func declineRequest(_ request: FriendRequest) async {
        guard let requestId = request.id else { return }
        do {
            try await FriendsService.shared.declineFriendRequest(requestId)
            await loadData()
        } catch {
            print("Error declining request: \(error)")
        }
    }
    
    private func deleteFriend(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let friend = friends[index]
                do {
                    try await FriendsService.shared.removeFriend(friend.userId)
                } catch {
                    print("Error removing friend: \(error)")
                }
            }
            await loadData()
        }
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: UserProfile
    
    var body: some View {
        NavigationLink {
            ProfileView(userId: friend.userId)
        } label: {
            HStack(spacing: 12) {
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(String(friend.displayName.prefix(1)))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.subheadline.weight(.medium))
                    
                    Text("@\(friend.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var senderProfile: UserProfile?
    
    var body: some View {
        HStack(spacing: 12) {
            if let profile = senderProfile {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(String(profile.displayName.prefix(1)))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName)
                        .font(.subheadline.weight(.medium))
                    
                    Text("wants to be friends".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onDecline()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .task {
            await loadSenderProfile()
        }
    }
    
    private func loadSenderProfile() async {
        do {
            senderProfile = try await FirebaseService.shared.getUserProfile(userId: request.fromUserId)
        } catch {
            print("Error loading sender profile: \(error)")
        }
    }
}

// MARK: - Empty State

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No Friends Yet".localized)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Add friends to share your essays privately".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Add Friend Sheet

struct AddFriendSheet: View {
    @State private var searchUsername = ""
    @State private var searchResult: UserProfile?
    @State private var searchError: String?
    @State private var isSearching = false
    @State private var requestStatus: FriendRequestStatus = .none
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Enter username".localized, text: $searchUsername)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if isSearching {
                            ProgressView()
                        } else {
                            Button("Search".localized) {
                                Task {
                                    await searchUser()
                                }
                            }
                            .disabled(searchUsername.isEmpty)
                        }
                    }
                }
                
                if let error = searchError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                if let user = searchResult {
                    Section("Search Result".localized) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Text(String(user.displayName.prefix(1)))
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if !user.bio.isEmpty {
                                    Text(user.bio)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if requestStatus == .none {
                            Button {
                                Task {
                                    await sendRequest(to: user.userId)
                                }
                            } label: {
                                Text("Send Friend Request".localized)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else if requestStatus == .requestSent {
                            Label("Request Sent".localized, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if requestStatus == .friends {
                            Label("Already Friends".localized, systemImage: "person.2.fill")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle("Add Friend".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchUser() async {
        isSearching = true
        searchError = nil
        searchResult = nil
        requestStatus = .none
        
        do {
            if let user = try await FirebaseService.shared.getUserProfileByUsername(searchUsername) {
                searchResult = user
                requestStatus = try await FriendsService.shared.getFriendRequestStatus(with: user.userId)
                if try await FriendsService.shared.isFriend(with: user.userId) {
                    requestStatus = .friends
                }
            } else {
                searchError = "User not found".localized
            }
        } catch {
            searchError = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func sendRequest(to userId: String) async {
        do {
            try await FriendsService.shared.sendFriendRequest(to: userId)
            requestStatus = .requestSent
        } catch {
            searchError = error.localizedDescription
        }
    }
}

#Preview {
    FriendsView()
}
