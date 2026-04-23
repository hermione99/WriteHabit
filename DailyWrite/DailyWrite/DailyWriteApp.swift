import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AppTrackingTransparency
import AdSupport
import FirebaseInAppMessaging

@main
struct DailyWriteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)  // Fixed to light theme
                .tint(Color(hex: "0D244D"))  // Indigo Rain accent
                .accentColor(Color(hex: "0D244D"))  // Fallback for older APIs
                .onAppear {
                    // Initialize notification service (UNUserNotificationCenter delegate)
                    _ = NotificationService.shared
                    
                    // Request notification permission for friend requests
                    Task {
                        _ = await NotificationService.shared.requestAuthorization()
                    }
                    
                    // Disable Firebase In-App Messaging
                    InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set Messaging delegate before anything else
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Configure Google Sign-In on main thread (UIKit requirement)
        DispatchQueue.main.async {
            if let clientID = FirebaseApp.app()?.options.clientID {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            }
        }
        
        // Request App Tracking Transparency permission (after delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("Tracking authorization status: \(status)")
                }
            }
        }
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Forward to NotificationService
        NotificationService.shared.handleFCMToken(fcmToken)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
