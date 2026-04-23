import SwiftUI
import FirebaseAuth

struct AllEssaysView: View {
    @State private var essays: [Essay] = []
    @State private var isLoading = true
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if essays.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No essays yet".localized)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Start writing to see your essays here".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(essays) { essay in
                        NavigationLink {
                            EssayDetailView(essay: essay)
                        } label: {
                            EssayListRow(essay: essay)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("All Essays".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadEssays()
        }
    }
    
    private func loadEssays() async {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            // Only fetch published essays (no drafts filter needed)
            let allEssays = try await FirebaseService.shared.getUserEssays(userId: user.uid)
            // Filter out deleted essays - only show active ones in "All Essays"
            essays = allEssays.filter { $0.deletedAt == nil }
        } catch {
            print("Error loading essays: \(error)")
        }
        
        isLoading = false
    }
}

struct EssayListRow: View {
    let essay: Essay
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Keyword badge with emoji
            HStack {
                let emoji = KeywordEmojiService.shared.emojiForKeyword(essay.keyword)
                Text("\(emoji) \(essay.keyword.isEmpty ? "No keyword" : essay.keyword)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForKeyword(essay.keyword))
                    )
                Spacer()
            }
            
            HStack {
                Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if essay.isDraft {
                    Text("Draft".localized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(4)
                }
                
                if essay.isPublic {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(themeManager.accent)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Prompt: \(essay.keyword)".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(essay.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(3)
            
            HStack {
                Text(formattedDate(essay.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text("\(essay.likesCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .font(.caption)
                        .foregroundStyle(themeManager.accent)
                    Text("\(essay.commentsCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Generate consistent color for each keyword
    private func colorForKeyword(_ keyword: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .pink, .purple, .teal, .indigo, .cyan, .mint, .red
        ]
        
        // Use hash of keyword to pick consistent color
        var hash = 0
        for char in keyword.unicodeScalars {
            hash = Int(char.value) + (hash << 6) + (hash << 16) - hash
        }
        
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

#Preview {
    AllEssaysView()
}
