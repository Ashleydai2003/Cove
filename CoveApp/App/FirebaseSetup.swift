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
    private var pendingFCMToken: String?
         func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         // Configure Firebase
         FirebaseApp.configure()
         
         // Configure Crashlytics
         configureCrashlytics()
         
         // Set messaging delegate
         Messaging.messaging().delegate = self
         
         // Set notification delegate
         UNUserNotificationCenter.current().delegate = self
         
         // Request notification permissions
         UNUserNotificationCenter.current().requestAuthorization(
             options: [.alert, .badge, .sound],
             completionHandler: { granted, error in
                 if let error = error { Log.error("Notification authorization error: \(error.localizedDescription)") }
                 Log.debug("Notification permission granted: \(granted)")
             }
         )
         
         // Register for remote notifications
         application.registerForRemoteNotifications()
 
         #if DEBUG
         // Use Firebase Auth emulator for local development
         Auth.auth().useEmulator(withHost: "localhost", port: 9099)
         Log.debug("[Firebase] Using Auth emulator at localhost:9099")
         #endif
 
         // Initialize WebSocket connection after Firebase setup
         initializeWebSocketConnection()

         // Print ID token (JWT) at launch if available
         Task { @MainActor in
             do {
                 if let token = try await Auth.auth().currentUser?.getIDToken() {
                     print("ID_TOKEN_LAUNCH: \(token)")
                 } else {
                     print("ID_TOKEN_LAUNCH: <nil>")
                 }
             }
         }

         // Auth listener: when user becomes available, flush any pending FCM token
         _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
             guard let self = self else { return }
             if let user = user {
                 Task {
                     if let token = try? await user.getIDToken() {
                         print("ID_TOKEN_AUTH: \(token)")
                     }
                     if let fcm = self.pendingFCMToken {
                         self.sendFCMTokenToBackend(fcm)
                         self.pendingFCMToken = nil
                     }
                 }
             } else {
                 print("ID_TOKEN_AUTH: <signed_out>")
             }
         }

         // Extra token fetch when app becomes active to refresh stale tokens
         NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
             guard let self = self else { return }
             Messaging.messaging().token { token, error in
                 if let token = token {
                     print("FCM_TOKEN_FOREGROUND: \(token)")
                     self.trySendFCMTokenIfAuthenticated(token)
                 } else if let error = error {
                     print("FCM_TOKEN_FOREGROUND_ERROR: \(error.localizedDescription)")
                 }
             }
         }

         return true
     }

         // Handle remote notification registration
     func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         // Provide APNs token to Firebase services
         Auth.auth().setAPNSToken(deviceToken, type: .prod)
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
        if let token = fcmToken {
            print("FCM_TOKEN_DEVICE: \(token)")
            pendingFCMToken = token
            trySendFCMTokenIfAuthenticated(token)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
         func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
         // Prefer in-app banner for richer control; fall back to system if requested
         if let payload = NotificationPayload(content: notification.request.content) {
             NotificationManager.shared.show(payload)
             // Suppress system banner when we have a valid in-app payload unless explicitly asked otherwise
             if payload.inAppOnly {
                 completionHandler([])
                 return
             }
         }
         completionHandler([.banner, .sound])
     }
    
         func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
         // Handle notification tap with validated payload and optional deep-link handling
         let content = response.notification.request.content
         if let payload = NotificationPayload(content: content) {
             if let url = payload.deepLink {
                 // Route via app-level router if available, otherwise openURL
                 Log.debug("Handling deep link from notification: \(url.absoluteString)")
                 DispatchQueue.main.async {
                     UIApplication.shared.open(url, options: [:], completionHandler: nil)
                 }
             }
         } else {
             // Fallback if payload cannot be parsed; pass raw userInfo for future handling
             handleNotificationTap(content.userInfo)
         }
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
    
    private func trySendFCMTokenIfAuthenticated(_ token: String) {
        Task {
            if let idToken = try? await Auth.auth().currentUser?.getIDToken(), !idToken.isEmpty {
                self.sendFCMTokenToBackend(token)
            } else {
                self.pendingFCMToken = token
            }
        }
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
             } else {
                 // No auth yet; queue token to retry later
                 self.pendingFCMToken = token
                 return
             }
             
             let body = ["fcmToken": token]
             request.httpBody = try? JSONSerialization.data(withJSONObject: body)
             
             URLSession.shared.dataTask(with: request) { data, response, error in
                 if let error = error {
                     Log.error("Failed to send FCM token: \(error)")
                     print("UPDATE_FCM_TOKEN_ERROR: \(error.localizedDescription)")
                 } else if let http = response as? HTTPURLResponse {
                     Log.debug("FCM token sent, status: \(http.statusCode)")
                     print("UPDATE_FCM_TOKEN_STATUS: \(http.statusCode)")
                 } else {
                     Log.debug("FCM token sent (no HTTPURLResponse)")
                     print("UPDATE_FCM_TOKEN_STATUS: unknown")
                 }
             }.resume()
         }
     }
    
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Route based on our notification type when possible; fall back to deeplink
        if let payload = NotificationPayload(userInfo: userInfo) {
            routeForPayload(payload)
            return
        }
        // Fallback: try deeplink key
        if let link = userInfo["deeplink"] as? String, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    /// Centralizes tap routing to keep logic consistent and testable
    private func routeForPayload(_ payload: NotificationPayload) {
        if let url = payload.deepLink {
            UIApplication.shared.open(url)
            return
        }
        // Construct common deep links when not provided explicitly
        switch payload.type {
        case .friendRequestReceived:
            // Navigate to requests inbox
            if let url = URL(string: "cove://friends/requests") { UIApplication.shared.open(url) }
        case .friendRequestAccepted:
            if let userId = payload.actorUserId, let url = URL(string: "cove://profile/\(userId)") {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "cove://friends") { UIApplication.shared.open(url) }
        case .coveInvite:
            if let url = URL(string: "cove://inbox") { UIApplication.shared.open(url) }
        case .coveEventCreated:
            if let coveId = payload.coveId, let eventId = payload.eventId, let url = URL(string: "cove://coves/\(coveId)/events/\(eventId)") {
                UIApplication.shared.open(url)
            } else if let coveId = payload.coveId, let url = URL(string: "cove://coves/\(coveId)") {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "cove://events") {
                UIApplication.shared.open(url)
            }
        case .coveEventRSVP:
            // Navigate to the event attendees or event details
            if let coveId = payload.coveId, let eventId = payload.eventId, let url = URL(string: "cove://coves/\(coveId)/events/\(eventId)/attendees") {
                UIApplication.shared.open(url)
            } else if let coveId = payload.coveId, let eventId = payload.eventId, let url = URL(string: "cove://coves/\(coveId)/events/\(eventId)") {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "cove://events") {
                UIApplication.shared.open(url)
            }
        case .none:
            break
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
