import SwiftUI

struct ShareEssayView: View {
    let essay: Essay
    @StateObject private var themeManager = ThemeManager.shared
    @State private var friends: [UserProfile] = []
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedFriends: Set<String> = []
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLoading = true
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showSuccess = false
    @StateObject private var themeManager = ThemeManager.shared
    @State private var message = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Essay preview
                Section("Sharing".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                            .font(.headline)
                        
                        Text(essay.keyword)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(essay.content.prefix(100) + (essay.content.count > 100 ? "..." : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                
                // Friends list
                Section("Select Friends".localized) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if friends.isEmpty {
                        Text("No friends yet. Add friends to share your writing!".localized)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(friends) { friend in
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: selectedFriends.contains(friend.userId)
                            ) {
                                toggleSelection(friend.userId)
                            }
                        }
                    }
                }
                
                // Share button
                if !friends.isEmpty {
                    Section {
                        Button {
                            Task {
                                await shareEssay()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Share with \(selectedFriends.count) Friends".localized)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedFriends.isEmpty ? Color.gray : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedFriends.isEmpty)
                    }
                }
            }
            .navigationTitle("Share Essay".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Shared!".localized, isPresented: $showSuccess) {
                Button("OK".localized, role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(message)
            }
            .task {
                await loadFriends()
            }
        }
    }
    
    private func loadFriends() async {
        do {
            friends = try await FriendsService.shared.getFriends()
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }
    
    private func toggleSelection(_ userId: String) {
        if selectedFriends.contains(userId) {
            selectedFriends.remove(userId)
        } else {
            selectedFriends.insert(userId)
        }
    }
    
    private func shareEssay() async {
        var successCount = 0
        
        for friendId in selectedFriends {
            do {
                try await FriendsService.shared.shareEssay(essay, with: friendId)
                successCount += 1
            } catch {
                print("Error sharing with \(friendId): \(error)")
            }
        }
        
        if successCount > 0 {
            message = String(format: "Successfully shared with %d friends!".localized, successCount)
            showSuccess = true
        }
    }
}

// MARK: - Friend Selection Row

struct FriendSelectionRow: View {
    let friend: UserProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accent.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(String(friend.displayName.prefix(1)))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.subheadline.weight(.medium))
                    
                    Text("@\(friend.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    ShareEssayView(essay: Essay(
        id: "1",
        authorId: "user1",
        authorName: "Test User",
        keyword: "Happiness",
        title: "My Essay",
        content: "This is a test essay content...",
        wordCount: 100,
        visibility: .friends,
        isDraft: false,
        createdAt: Date(),
        updatedAt: Date(),
        likesCount: 0,
        commentsCount: 0
    ))
}
