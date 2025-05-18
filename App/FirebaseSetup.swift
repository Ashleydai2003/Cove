//
//  FirebaseSetup.swift
//  Cove
//
//  Created by Nina Boord on 4/26/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import IQKeyboardManagerSwift

class FirebaseSetup: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("Initializing Firebase...")
        
        do {
            FirebaseApp.configure()
            print("Firebase configured successfully")
        } catch {
            print("Error configuring Firebase: \(error)")
            return false
        }
        
        // Enable IQKeyboardManager to prevent issues of keyboard sliding up
        IQKeyboardManager.shared.enable = true
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
                return
            }
            
            if granted {
                print("Notification permissions granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions denied")
            }
        }
        
        return true
    }
    
    // Handle remote notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for remote notifications")
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // Handle incoming remote notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification")
        if Auth.auth().canHandleNotification(userInfo) {
            print("Firebase handled the notification")
            completionHandler(.noData)
            return
        }
        print("Firebase did not handle the notification")
        completionHandler(.noData)
    }
}
