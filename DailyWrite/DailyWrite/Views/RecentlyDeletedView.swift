import SwiftUI
import FirebaseAuth

struct RecentlyDeletedView: View {
    @State private var deletedEssays: [Essay] = []
    @State private var isLoading = false
    @State private var selectedEssay: Essay?
    @State private var showingRecoverAlert = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if deletedEssays.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                Text("No recently deleted essays".localized)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Deleted essays will appear here for 30 days".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                    }
                } else {
                    Section {
                        ForEach(deletedEssays) { essay in
                            DeletedEssayRow(essay: essay)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        selectedEssay = essay
                                        showingRecoverAlert = true
                                    } label: {
                                        Label("Recover".localized, systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        selectedEssay = essay
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete".localized, systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    } footer: {
                        Text("Essays are permanently deleted after 30 days.".localized)
                    }
                }
            }
            .navigationTitle("Recently Deleted".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .task {
                await loadDeletedEssays()
            }
            .alert("Recover Essay?".localized, isPresented: $showingRecoverAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Recover".localized) {
                    if let essay = selectedEssay {
                        Task {
                            await recoverEssay(essay)
                        }
                    }
                }
            } message: {
                if let essay = selectedEssay {
                    Text("Recover \"\(essay.title.isEmpty ? "Untitled" : essay.title)\"?")
                }
            }
            .alert("Delete Permanently?".localized, isPresented: $showingDeleteAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Delete".localized, role: .destructive) {
                    if let essay = selectedEssay {
                        Task {
                            await permanentlyDeleteEssay(essay)
                        }
                    }
                }
            } message: {
                Text("This action cannot be undone. The essay will be permanently deleted.".localized)
            }
        }
    }
    
    private func loadDeletedEssays() async {
        isLoading = true
        do {
            if let userId = Auth.auth().currentUser?.uid {
                deletedEssays = try await FirebaseService.shared.getRecentlyDeletedEssays(userId: userId)
            }
        } catch {
            print("Error loading deleted essays: \(error)")
        }
        isLoading = false
    }
    
    private func recoverEssay(_ essay: Essay) async {
        do {
            try await FirebaseService.shared.recoverEssay(essayId: essay.id ?? "")
            await loadDeletedEssays()
        } catch {
            print("Error recovering essay: \(error)")
        }
    }
    
    private func permanentlyDeleteEssay(_ essay: Essay) async {
        guard let essayId = essay.id, !essayId.isEmpty else {
            print("Error: Essay ID is nil or empty")
            return
        }
        do {
            try await FirebaseService.shared.permanentlyDeleteEssay(essayId: essayId)
            await loadDeletedEssays()
        } catch {
            print("Error permanently deleting essay: \(error)")
        }
    }
}

struct DeletedEssayRow: View {
    let essay: Essay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(essay.title.isEmpty ? "Untitled".localized : essay.title)
                .font(.headline)
            
            Text(essay.keyword)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if essay.daysUntilPermanentDelete > 0 {
                Text("Deletes in \(essay.daysUntilPermanentDelete) days".localized)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                Text("Deleting soon".localized)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecentlyDeletedView()
}
