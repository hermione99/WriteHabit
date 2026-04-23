import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Extension to chunk array for Firestore 'in' query limit
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct KeywordBrowseView: View {
    let keyword: String
    @State private var essays: [Essay] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header - keyword centered, no ORIGIN
                    HStack {
                        Spacer()
                        
                        Text(keyword.uppercased())
                            .font(.system(size: 32, weight: .black, design: .serif))
                            .tracking(2)
                            .foregroundColor(Color(hex: "0D244D"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(essays.count)개의 글")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "0D244D").opacity(0.6))
                        
                        Spacer()
                    }
                    .padding(.bottom, 12)
                    
                    Divider()
                        .background(Color(hex: "0D244D").opacity(0.1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if essays.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "0D244D").opacity(0.3))
                            
                            Text("아직 글이 없습니다")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "0D244D").opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(essays) { essay in
                                    NavigationLink(value: essay) {
                                        EssayCard(essay: essay)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "0D244D"))
                    }
                }
            }
            .navigationDestination(for: Essay.self) { essay in
                EssayDetailView(essay: essay)
            }
            .task {
                await loadEssays()
            }
        }
    }
    
    private func loadEssays() async {
        isLoading = true
        defer { isLoading = false }
        
        print("[DEBUG] loadEssays() called with keyword: '\(keyword)'")
        
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("[DEBUG] No user ID")
            return 
        }
        
        do {
            let db = Firestore.firestore()
            
            // 1. Get my friends list from user document
            print("[DEBUG] Fetching friends for user: \(userId)")
            let userDoc = try await db.collection("users").document(userId).getDocument()
            let friendIds = Set(userDoc.data()?["friends"] as? [String] ?? [])
            print("[DEBUG] Found \(friendIds.count) friends: \(friendIds)")
            
            // 2. Query ALL essays for this keyword (filter deleted in memory)
            print("[DEBUG] Querying Firestore for keyword: '\(keyword)'")
            let snapshot = try await db.collection("essays")
                .whereField("keyword", isEqualTo: keyword)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            print("[DEBUG] Firestore returned \(snapshot.documents.count) total documents")
            
            print("[DEBUG] Firestore returned \(snapshot.documents.count) documents")
            
            // 3. Filter and sort in memory
            let allEssays = snapshot.documents.compactMap { doc -> Essay? in
                // Check deletedAt (skip if exists - means deleted)
                if doc.data()["deletedAt"] != nil {
                    print("[DEBUG] Skipping deleted essay (docID: \(doc.documentID))")
                    return nil
                }
                
                guard let essay = try? doc.data(as: Essay.self) else { 
                    print("[DEBUG] Failed to parse essay: \(doc.documentID)")
                    return nil 
                }
                
                let essayUserId = essay.authorId
                let isMine = essayUserId == userId
                let isFriend = friendIds.contains(essayUserId)
                
                // Visibility check - handle both old and new essays
                let visibility = essay.visibility
                let isPublic = visibility == .public
                let isFriendsOnly = visibility == .friends
                let isPrivate = visibility == .private
                
                print("[DEBUG] Essay \(essay.id ?? "nil"): isMine=\(isMine), isFriend=\(isFriend), visibility=\(visibility), isPublic=\(isPublic)")
                
                if isMine {
                    // My essay: always show
                    print("[DEBUG] Including my essay")
                    return essay
                } else if isPublic {
                    // Public essay: show to everyone
                    print("[DEBUG] Including public essay")
                    return essay
                } else if isFriendsOnly && isFriend {
                    // Friend's friends-only essay: show to friends
                    print("[DEBUG] Including friend's friends-only essay")
                    return essay
                } else if isPrivate && isFriend {
                    // Friend's private essay: show to friends (optional, remove if not needed)
                    print("[DEBUG] Including friend's private essay")
                    return essay
                }
                
                print("[DEBUG] Excluding essay - no visibility match")
                return nil
            }.sorted(by: { $0.createdAt > $1.createdAt })  // Memory sort
            
            await MainActor.run {
                essays = [] // Clear first
                essays = allEssays
                print("[DEBUG] KeywordBrowseView: Loaded \(allEssays.count) essays for keyword '\(keyword)'")
            }
            
        } catch {
            print("Error loading essays for keyword: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}

struct EssayCard: View {
    let essay: Essay
    
    @State private var showingDetail = false
    
    private let indigoColor = Color(hex: "0D244D")
    private let paperColor = Color(hex: "FDFBF7")
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            ZStack {
                // Clean paper background with subtle shadow
                Rectangle()
                    .fill(paperColor)
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 6,
                        x: 1,
                        y: 2
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Author row
                    HStack(spacing: 10) {
                        // Avatar
                        Circle()
                            .fill(indigoColor.opacity(0.08))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(indigoColor.opacity(0.4))
                                    .font(.system(size: 12))
                            )
                        
                        Text(essay.authorName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(indigoColor.opacity(0.8))
                        
                        Spacer()
                        
                        Text(timeAgo(from: essay.createdAt))
                            .font(.system(size: 11))
                            .foregroundStyle(indigoColor.opacity(0.35))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    
                    // Thin separator
                    Rectangle()
                        .fill(indigoColor.opacity(0.06))
                        .frame(height: 0.5)
                        .padding(.horizontal, 18)
                    
                    // Content area
                    VStack(alignment: .leading, spacing: 8) {
                        // Keyword
                        HStack {
                            let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
                            Text("\(emoji) \(essay.keyword)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(indigoColor.opacity(0.5))
                            
                            Spacer()
                        }
                        
                        // Title
                        if !essay.title.isEmpty {
                            Text(essay.title)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundStyle(indigoColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Preview
                        Text(essay.content)
                            .font(.system(size: 14))
                            .foregroundStyle(indigoColor.opacity(0.7))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    
                    // Bottom stats row
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 12))
                            Text("\(essay.likesCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(indigoColor.opacity(0.4))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 12))
                            Text("\(essay.wordCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(indigoColor.opacity(0.4))
                        
                        Spacer()
                        
                        // Visibility icon
                        Image(systemName: essay.visibility == .public ? "globe" : "lock")
                            .font(.system(size: 12))
                            .foregroundStyle(indigoColor.opacity(0.3))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            EssayDetailView(essay: essay)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    KeywordBrowseView(keyword: "Test")
}
