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
import UserNotifications
import IQKeyboardManagerSwift

class FirebaseSetup: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { _, _ in }
        )
        
        // Register for remote notifications
        application.registerForRemoteNotifications()

        #if DEBUG
        // Use Firebase Auth emulator for local development
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        Log.debug("[Firebase] Using Auth emulator at localhost:9099")
        #endif

        // Initialize WebSocket connection after Firebase setup
        // initializeWebSocketConnection() // Temporarily removed - will reimplement

        return true
    }

    // Handle remote notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
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
        Log.debug("Firebase registration token: \(String(describing: fcmToken))")
        
        // Send FCM token to your backend
        if let token = fcmToken {
            sendFCMTokenToBackend(token)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo)
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    private func sendFCMTokenToBackend(_ token: String) {
        // FCM token will be handled when WebSocket is reimplemented
        Log.debug("FCM token received: \(token)")
        
        // Store token for future WebSocket implementation
        UserDefaults.standard.set(token, forKey: "FCM_TOKEN")
        
        // TODO: Implement FCM token update when WebSocket is reimplemented
        Log.debug("FCM token available for WebSocket: \(token)")
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
    
    // WebSocket will be reimplemented from scratch
    // private func initializeWebSocketConnection() {
    //     Log.debug("Initializing WebSocket connection", category: "websocket")
    //     
    //     // Connect to WebSocket when user is authenticated
    //     _ = Auth.auth().addStateDidChangeListener { _, user in
    //         if user != nil {
    //             Log.debug("User authenticated, connecting to WebSocket", category: "websocket")
    //             // Get fresh Firebase token and connect
    //             user?.getIDTokenForcingRefresh(true) { token, error in
    //                 if let token = token {
    //                     DispatchQueue.main.async {
    //                         // TODO: Implement WebSocket connection
    //                     }
    //                 } else if let error = error {
    //                     Log.error("Failed to get fresh token: \(error.localizedDescription)", category: "websocket")
    //                 }
    //             }
    //         } else {
    //             Log.debug("User signed out, disconnecting from WebSocket", category: "websocket")
    //             // TODO: Implement WebSocket disconnection
    //         }
    //     }
    // }
}
