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
                    List {
                        ForEach(drafts) { draft in
                            Button {
                                selectedDraft = draft
                                showingEditor = true
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(draft.title.isEmpty ? "Untitled" : draft.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(draft.updatedAt, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text("Keyword".localized + ": \(draft.keyword)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(draft.content)
                                        .font(.body)
                                        .lineLimit(3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteDraft)
                    }
                    .fullScreenCover(item: $selectedDraft) { draft in
                        NavigationStack {
                            SimpleWritingEditorView(keyword: draft.keyword, existingEssay: draft, isDraft: true)
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
            .id(UUID()) // Force refresh when view appears
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
            // Check for nil IDs
            let nilIds = drafts.filter { $0.id == nil }.count
            if nilIds > 0 {
                print("[WARNING] \(nilIds) drafts have nil ID!")
            }
            for (index, draft) in drafts.enumerated() {
                print("[DEBUG] Draft \(index): id=\(draft.id ?? "nil"), title=\(draft.title), keyword=\(draft.keyword), content=\(draft.content.prefix(30))...")
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
                // Get the drafts to delete
                let draftsToDelete = offsets.map { drafts[$0] }
                
                // Delete from Firebase
                for draft in draftsToDelete {
                    if let essayId = draft.id {
                        try await FirebaseService.shared.deleteEssay(essayId: essayId)
                    }
                }
                
                // Remove from local array
                drafts.remove(atOffsets: offsets)
                
            } catch {
                print("Error deleting draft: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}
