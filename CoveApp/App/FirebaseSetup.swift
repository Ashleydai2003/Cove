//
//  FirebaseSetup.swift
//  Cove
//
//  Created by Nina Boord on 4/26/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import FirebaseCrashlytics
import UserNotifications
import IQKeyboardManagerSwift

class FirebaseSetup: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Crashlytics
        configureCrashlytics()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        // Enable automatic FCM registration
        Messaging.messaging().isAutoInitEnabled = true
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        // Register categories/actions and request authorization centrally
        NotificationManager.registerCategories()
        NotificationManager.requestAuthorization()
        
        // Request notification permissions
        // (Handled by NotificationManager)
        
        // Register for remote notifications
        application.registerForRemoteNotifications()

        // Proactively fetch FCM token (in case delegate callback timing varies)
        Messaging.messaging().token { token, error in
            if let error = error {
                Log.error("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                Log.debug("Fetched FCM token")
                TokenUploader.upload(token: token)
            }
        }

        #if DEBUG
        // Use Firebase Auth emulator for local development
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        Log.debug("[Firebase] Using Auth emulator at localhost:9099")
        #endif

        // Initialize WebSocket connection after Firebase setup
        initializeWebSocketConnection()

        return true
    }

    // Handle remote notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Inform Firebase Auth of the APNs token for auth flows
        #if DEBUG
        let apnsType: AuthAPNSTokenType = .sandbox
        #else
        let apnsType: AuthAPNSTokenType = .prod
        #endif
        Auth.auth().setAPNSToken(deviceToken, type: apnsType)

        // Inform Firebase Messaging so it can map APNs token to FCM token
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle incoming remote notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log.debug("Received remote notification")
        if Auth.auth().canHandleNotification(userInfo) {
            Log.debug("Firebase handled the notification")
            completionHandler(.noData)
            return
        }
        Log.debug("Firebase did not handle the notification")
        completionHandler(.noData)
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Log.debug("Firebase registration token received")
        
        // Send FCM token to your backend
        if let token = fcmToken {
            TokenUploader.upload(token: token)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([[.banner, .list, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        PushRouter.route(from: userInfo, actionIdentifier: response.actionIdentifier)
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    /// Configures Crashlytics with user identification and custom keys
    private func configureCrashlytics() {
        // Set custom keys for better crash analysis
        Crashlytics.crashlytics().setCustomValue(AppConstants.API.environment, forKey: "environment")
        Crashlytics.crashlytics().setCustomValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown", forKey: "app_version")
        
        // Listen for auth state changes to set user ID
        _ = Auth.auth().addStateDidChangeListener { _, user in
            if let user = user {
                Crashlytics.crashlytics().setUserID(user.uid)
                Log.debug("[Crashlytics] Set user ID: \(user.uid)")
            } else {
                Crashlytics.crashlytics().setUserID("anonymous")
                Log.debug("[Crashlytics] Set anonymous user")
            }
        }
        
        Log.debug("[Crashlytics] Initialized successfully")
        
        #if DEBUG
        // Test Crashlytics integration in DEBUG builds
        CrashlyticsHandler.testIntegration()
        #endif
    }
    
    private func sendFCMTokenToBackend(_ token: String) {
        // Send token to your backend API
        guard let url = URL(string: "\(AppConstants.API.baseURL)/update-fcm-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add your authentication header
        Task {
            if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
                request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            }
            
            let body = ["fcmToken": token]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    Log.error("Failed to send FCM token: \(error)")
                } else {
                    Log.debug("FCM token sent successfully")
                }
            }.resume()
        }
    }
    
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Handle notification tap - navigate to appropriate screen
        if let threadId = userInfo["threadId"] as? String {
            // Navigate to the specific thread
            // This depends on your app's navigation structure
            Log.debug("Notification tapped for thread: \(threadId)")
        }
    }
    
    // MARK: - WebSocket Management
    
    private func initializeWebSocketConnection() {
        Log.debug("Initializing WebSocket connection", category: "websocket")
        
        // Connect to WebSocket when user is authenticated
        _ = Auth.auth().addStateDidChangeListener { _, user in
            if user != nil {
                Log.debug("User authenticated, connecting to WebSocket", category: "websocket")
                WebSocketManager.shared.connect()
            } else {
                Log.debug("User signed out, disconnecting from WebSocket", category: "websocket")
                WebSocketManager.shared.disconnect()
            }
        }
    }
}
