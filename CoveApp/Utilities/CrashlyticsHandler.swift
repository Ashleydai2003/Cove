//
//  CrashlyticsHandler.swift
//  Cove
//
//  Created by Assistant
//

import Foundation
import FirebaseCrashlytics

/// CrashlyticsHandler: Bridges our logging system to Firebase Crashlytics
/// This ensures all logs are captured in crash reports for better debugging
struct CrashlyticsHandler {
    
    /// Logs a message to Crashlytics breadcrumbs
    /// - Parameter message: The message to log
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// Logs an error to Crashlytics as a non-fatal error
    /// - Parameters:
    ///   - error: The error to record
    ///   - context: Additional context about the error
    static func recordError(_ error: Error, context: String? = nil) {
        let userInfo: [String: Any] = context != nil ? ["context": context!] : [:]
        
        let nsError = NSError(
            domain: "CoveApp",
            code: 0,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Logs a custom error with a specific domain and code
    /// - Parameters:
    ///   - domain: The error domain
    ///   - code: The error code
    ///   - message: The error message
    ///   - context: Additional context
    static func recordCustomError(domain: String, code: Int, message: String, context: String? = nil) {
        let userInfo: [String: Any] = context != nil ? [
            NSLocalizedDescriptionKey: message,
            "context": context!
        ] : [
            NSLocalizedDescriptionKey: message
        ]
        
        let nsError = NSError(
            domain: domain,
            code: code,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Sets a custom key-value pair in Crashlytics
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The key for the value
    static func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    /// Sets the user ID for crash reports
    /// - Parameter userId: The user ID to set
    static func setUserID(_ userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    /// Logs network errors specifically
    /// - Parameters:
    ///   - error: The network error
    ///   - endpoint: The API endpoint that failed
    ///   - method: The HTTP method used
    static func recordNetworkError(_ error: Error, endpoint: String, method: String) {
        let userInfo: [String: Any] = [
            "endpoint": endpoint,
            "method": method,
            NSLocalizedDescriptionKey: error.localizedDescription
        ]
        
        let nsError = NSError(
            domain: "CoveApp.Network",
            code: 0,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Logs onboarding errors specifically
    /// - Parameters:
    ///   - error: The onboarding error
    ///   - step: The onboarding step that failed
    static func recordOnboardingError(_ error: Error, step: String) {
        let userInfo: [String: Any] = [
            "step": step,
            NSLocalizedDescriptionKey: error.localizedDescription
        ]
        
        let nsError = NSError(
            domain: "CoveApp.Onboarding",
            code: 0,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Logs cove creation errors specifically
    /// - Parameters:
    ///   - error: The cove creation error
    ///   - context: Additional context about the cove creation
    static func recordCoveCreationError(_ error: Error, context: String? = nil) {
        let userInfo: [String: Any] = context != nil ? [
            NSLocalizedDescriptionKey: error.localizedDescription,
            "context": context!
        ] : [
            NSLocalizedDescriptionKey: error.localizedDescription
        ]
        
        let nsError = NSError(
            domain: "CoveApp.CoveCreation",
            code: 0,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Test method to verify Crashlytics integration
    /// Call this in DEBUG builds to test the integration
    static func testIntegration() {
        #if DEBUG
        log("Crashlytics integration test - this should appear in crash reports")
        setCustomValue("test_value", forKey: "test_key")
        recordCustomError(domain: "CoveApp.Test", code: 999, message: "Test error for Crashlytics integration")
        #endif
    }
} 