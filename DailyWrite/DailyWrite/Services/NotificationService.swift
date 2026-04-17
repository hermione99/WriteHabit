import Foundation
import UserNotifications
import SwiftUI
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore

// Manages daily writing reminder notifications
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var isFCMRegistered = false
    @Published var reminderTime: Date {
        didSet {
            saveReminderTime()
            scheduleDailyReminder()
        }
    }
    @Published var isReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isReminderEnabled, forKey: "reminderEnabled")
            if isReminderEnabled {
                scheduleDailyReminder()
            } else {
                cancelReminders()
            }
        }
    }
    
    private let center = UNUserNotificationCenter.current()
    private lazy var db = Firestore.firestore()
    
    override init() {
        // Load saved settings
        let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date
        self.reminderTime = savedTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.isReminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        
        super.init()
        center.delegate = self
        // Note: Messaging delegate is set in AppDelegate to avoid threading issues
        
        // Check current authorization
        checkAuthorization()
    }
    
    // Request notification permission
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    // Check current authorization status
    func checkAuthorization() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Schedule daily reminder
    func scheduleDailyReminder() {
        guard isReminderEnabled && isAuthorized else { return }
        
        // Cancel existing reminders
        cancelReminders()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = localizedTitle()
        content.body = localizedBody()
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_WRITING"
        
        // Create daily trigger at selected time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyWritingReminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error)")
            } else {
                print("Daily reminder scheduled for \(components.hour ?? 9):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }
    
    // Cancel all reminders
    func cancelReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyWritingReminder"])
        center.removeDeliveredNotifications(withIdentifiers: ["dailyWritingReminder"])
    }
    
    // Save reminder time
    private func saveReminderTime() {
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
    }
    
    // Localized notification text
    private func localizedTitle() -> String {
        let language = LanguageManager.shared.currentLanguage
        switch language {
        case .korean:
            return "✍️ 오늘의 글쓰기 시간"
        case .english:
            return "✍️ Time to Write"
        }
    }
    
    private func localizedBody() -> String {
        let language = LanguageManager.shared.currentLanguage
        let keyword = getTodayKeyword()
        switch language {
        case .korean:
            return "오늘의 키워드 '\(keyword)'에 대해 글을 써보세요. 당신의 이야기를 기다리고 있어요!"
        case .english:
            return "Write about today's keyword '\(keyword)'. Your story awaits!"
        }
    }
    
    // Get today's keyword (simplified, actual implementation would fetch from generator)
    private func getTodayKeyword() -> String {
        // This is a placeholder - in production, you'd get this from KeywordGenerator
        return LanguageManager.shared.currentLanguage == .korean ? "시작" : "Beginning"
    }
    
    // Test notification (for development)
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = localizedTitle()
        content.body = localizedBody()
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "testNotification",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        let userInfo = notification.request.content.userInfo
        
        // Check if it's an FCM message
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.notification.request.identifier
        
        if identifier == "dailyWritingReminder" {
            // Navigate to writing screen
            NotificationCenter.default.post(name: .init("OpenWritingEditor"), object: nil)
        }
        
        // Handle FCM notification taps
        if let type = userInfo["type"] as? String {
            switch type {
            case "like", "comment":
                if let essayId = userInfo["essayId"] as? String {
                    NotificationCenter.default.post(
                        name: .init("OpenEssayDetail"),
                        object: nil,
                        userInfo: ["essayId": essayId]
                    )
                }
            case "friendRequest":
                NotificationCenter.default.post(name: .init("OpenFriends"), object: nil)
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showPermissionAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Daily Reminder".localized, isOn: $notificationService.isReminderEnabled)
                        .onChange(of: notificationService.isReminderEnabled) { newValue in
                            if newValue && !notificationService.isAuthorized {
                                Task {
                                    let granted = await notificationService.requestAuthorization()
                                    if !granted {
                                        notificationService.isReminderEnabled = false
                                        showPermissionAlert = true
                                    }
                                }
                            }
                        }
                } footer: {
                    Text("Receive a daily notification to remind you to write.".localized)
                        .font(.caption)
                }
                
                if notificationService.isReminderEnabled {
                    Section("Reminder Time".localized) {
                        DatePicker(
                            "Time".localized,
                            selection: $notificationService.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                    
                    Section {
                        Button {
                            notificationService.sendTestNotification()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Send Test Notification".localized)
                                Spacer()
                            }
                        }
                    }
                }
                
                if !notificationService.isAuthorized {
                    Section {
                        Button {
                            openSettings()
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings to Enable Notifications".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Notifications".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Permission Required".localized, isPresented: $showPermissionAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Settings".localized) {
                    openSettings()
                }
            } message: {
                Text("Please enable notifications in Settings to receive daily reminders.".localized)
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// Localization strings needed:
// "Enable Daily Reminder" = "Enable Daily Reminder"
// "Receive a daily notification to remind you to write." = "Receive a daily notification to remind you to write."
// "Reminder Time" = "Reminder Time"
// "Time" = "Time"
// "Send Test Notification" = "Send Test Notification"
// "Open Settings to Enable Notifications" = "Open Settings to Enable Notifications"
// "Notifications" = "Notifications"
// "Permission Required" = "Permission Required"
// "Please enable notifications in Settings to receive daily reminders." = "Please enable notifications in Settings to receive daily reminders."
// "Settings" = "Settings"

// MARK: - FCM Token Management

extension NotificationService {
    func handleFCMToken(_ fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let token = fcmToken else { return }
        
        // Save token to Firestore
        Task {
            await saveFCMToken(token)
        }
        
        // Notify app about token
        let dataDict: [String: String] = ["token": token]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        handleFCMToken(fcmToken)
    }
    
    func saveFCMToken(_ token: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "fcmTokenUpdatedAt": Timestamp(date: Date())
            ])
            await MainActor.run {
                isFCMRegistered = true
            }
            print("FCM token saved successfully")
        } catch {
            print("Error saving FCM token: \(error)")
        }
    }
    
    func deleteFCMToken() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": FieldValue.delete(),
                "fcmTokenUpdatedAt": FieldValue.delete()
            ])
            await MainActor.run {
                isFCMRegistered = false
            }
            print("FCM token deleted successfully")
        } catch {
            print("Error deleting FCM token: \(error)")
        }
    }
    
    // MARK: - Comment/Reply Notifications
    
    /// Sends a notification to the essay author when someone comments
    func notifyEssayAuthorOfComment(essayId: String, essayAuthorId: String, commenterName: String, commentContent: String) async {
        // Don't notify if user is commenting on their own essay
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != essayAuthorId else { return }
        
        #if DEBUG
        print("[DEBUG Notification] Sending comment notification to user: \(essayAuthorId)")
        #endif
        
        // Create in-app notification
        let notification = InAppNotification(
            id: nil,
            userId: essayAuthorId,
            type: .comment,
            title: "New Comment".localized,
            body: String(format: "%@ commented on your essay".localized, commenterName),
            relatedId: essayId,
            isRead: false,
            createdAt: Date()
        )
        
        do {
            try await saveInAppNotification(notification)
            #if DEBUG
            print("[DEBUG Notification] Saved in-app notification successfully")
            #endif
            
            // Queue push notification for Cloud Functions
            await sendPushNotification(
                to: essayAuthorId,
                title: "New Comment".localized,
                body: "\(commenterName): \(String(commentContent.prefix(50)))\(commentContent.count > 50 ? "..." : "")"
            )
        } catch {
            print("Error sending comment notification: \(error)")
        }
    }
    
    /// Sends a notification when someone replies to a comment
    func notifyCommentAuthorOfReply(parentCommentId: String, parentCommentAuthorId: String, replierName: String, replyContent: String, essayId: String) async {
        // Don't notify if user is replying to their own comment
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != parentCommentAuthorId else { return }
        
        #if DEBUG
        print("[DEBUG Notification] Sending reply notification to user: \(parentCommentAuthorId)")
        #endif
        
        let notification = InAppNotification(
            id: nil,
            userId: parentCommentAuthorId,
            type: .reply,
            title: "New Reply".localized,
            body: String(format: "%@ replied to your comment".localized, replierName),
            relatedId: essayId,
            isRead: false,
            createdAt: Date()
        )
        
        do {
            try await saveInAppNotification(notification)
            #if DEBUG
            print("[DEBUG Notification] Saved in-app notification successfully")
            #endif
            
            await sendPushNotification(
                to: parentCommentAuthorId,
                title: "New Reply".localized,
                body: "\(replierName): \(String(replyContent.prefix(50)))\(replyContent.count > 50 ? "..." : "")"
            )
        } catch {
            print("Error sending reply notification: \(error)")
        }
    }
    
    private func saveInAppNotification(_ notification: InAppNotification) async throws {
        let docRef = db.collection("notifications").document()
        try await docRef.setData(notification.dictionary)
    }
    
    private func sendPushNotification(to userId: String, title: String, body: String) async {
        do {
            // Fetch user's FCM token
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let fcmToken = userDoc.data()?["fcmToken"] as? String else {
                print("No FCM token for user \(userId)")
                return
            }
            
            // Send notification via FCM (this would typically be done server-side)
            // For now, we'll rely on Firestore triggers in Firebase Cloud Functions
            // to send actual push notifications
            print("Would send push notification to token: \(fcmToken.prefix(20))...")
            
            // Store notification in Firestore for Cloud Function to pick up
            let messageRef = db.collection("pushNotifications").document()
            try await messageRef.setData([
                "token": fcmToken,
                "title": title,
                "body": body,
                "userId": userId,
                "sent": false,
                "createdAt": Timestamp(date: Date())
            ])
        } catch {
            print("Error sending push notification: \(error)")
        }
    }
}
