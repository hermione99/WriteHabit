import SwiftUI
import FirebaseAuth

struct DraftsView: View {
    @State private var drafts: [Essay] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedDraft: Essay?
    @State private var showingEditor = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F0E8")
                    .ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView()
                    } else if drafts.isEmpty {
                        ContentUnavailableView(
                            "No Drafts".localized,
                            systemImage: "doc.text",
                            description: Text("Start writing to save drafts".localized)
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(drafts) { draft in
                                    draftCard(for: draft)
                                        .onTapGesture {
                                            selectedDraft = draft
                                            showingEditor = true
                                        }
                                }
                                .onDelete(perform: deleteDraft)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Drafts".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $selectedDraft) { draft in
                NavigationStack {
                    SimpleWritingEditorView(keyword: draft.keyword, existingEssay: draft, isDraft: true)
                }
            }
            .id(UUID())
            .task {
                await loadDrafts()
            }
            .onAppear {
                Task {
                    await loadDrafts()
                }
            }
        }
    }
    
    private func loadDrafts() async {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("No user logged in")
            isLoading = false
            return 
        }
        
        print("Loading drafts for user: \(userId)")
        
        do {
            drafts = try await FirebaseService.shared.getUserDrafts(userId: userId)
            print("Loaded \(drafts.count) drafts")
            let nilIds = drafts.filter { $0.id == nil }.count
            if nilIds > 0 {
                print("[WARNING] \(nilIds) drafts have nil ID!")
            }
            isLoading = false
        } catch {
            print("Error loading drafts: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func deleteDraft(at offsets: IndexSet) {
        Task {
            do {
                let draftsToDelete = offsets.map { drafts[$0] }
                
                for draft in draftsToDelete {
                    if let essayId = draft.id {
                        try await FirebaseService.shared.deleteEssay(essayId: essayId)
                    }
                }
                
                drafts.remove(atOffsets: offsets)
            } catch {
                print("Error deleting draft: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Card View
    private func draftCard(for draft: Essay) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top label bar
            HStack {
                Text(draft.updatedAt, style: .date)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color(hex: "4A5A30"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "E8E0D0"))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(draft.keyword.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "4A5A30"))
                
                Text(draft.title.isEmpty ? "Untitled" : draft.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(draft.content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            
            // Bottom divider with status
            HStack {
                Text("Draft".localized.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color(hex: "C2441C"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "4A5A30"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "F0EBE3"))
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color(hex: "D4CFC3"), lineWidth: 1)
        )
    }
}
