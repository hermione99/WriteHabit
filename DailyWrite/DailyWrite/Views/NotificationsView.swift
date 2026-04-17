import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationsView: View {
    @State private var notifications: [InAppNotification] = []
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
                } else if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No notifications yet".localized)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture {
                                handleNotificationTap(notification)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteNotification(notification)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications".localized)
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
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            notifications = snapshot.documents.compactMap { doc in
                try? doc.data(as: InAppNotification.self)
            }.sorted { $0.createdAt > $1.createdAt }  // Sort in Swift instead
            
            // Mark all as read
            await markAllAsRead()
        } catch {
            print("Error loading notifications: \(error)")
        }
        
        isLoading = false
    }
    
    private func markAllAsRead() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            for doc in snapshot.documents {
                try await doc.reference.updateData(["isRead": true])
            }
        } catch {
            print("Error marking notifications as read: \(error)")
        }
    }
    
    private func deleteNotification(_ notification: InAppNotification) {
        guard let id = notification.id else { return }
        
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection("notifications").document(id).delete()
                
                await MainActor.run {
                    notifications.removeAll { $0.id == id }
                }
            } catch {
                print("Error deleting notification: \(error)")
            }
        }
    }
    
    private func handleNotificationTap(_ notification: InAppNotification) {
        // Mark as read immediately
        Task {
            if let id = notification.id {
                let db = Firestore.firestore()
                try? await db.collection("notifications").document(id).updateData(["isRead": true])
            }
        }
        
        // Navigate to the essay (using the relatedId from notification)
        if let essayId = notification.relatedId {
            // Post notification for navigation
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToEssay"),
                object: nil,
                userInfo: ["essayId": essayId]
            )
            
            // Dismiss this view
            dismiss()
        }
    }
}

struct NotificationRow: View {
    let notification: InAppNotification
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on type
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(themeManager.accent)
                .frame(width: 40, height: 40)
                .background(themeManager.accent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(notification.isRead ? .secondary : .primary)
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(themeManager.accent)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch notification.type {
        case .comment:
            return "bubble.left.fill"
        case .reply:
            return "arrow.turn.up.left"
        case .like:
            return "heart.fill"
        case .friendRequest:
            return "person.badge.plus"
        case .follow:
            return "person.fill.checkmark"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsView()
}
