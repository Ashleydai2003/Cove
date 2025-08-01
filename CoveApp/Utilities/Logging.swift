import Foundation
import os
import FirebaseCrashlytics

/// Simple wrapper around Swift's os.Logger that silences logs in non-DEBUG builds
/// and provides convenient static helpers. Also integrates with Firebase Crashlytics
/// for better crash reporting and log buffering.
///
/// Usage:
///   Log.debug("Loaded profile successfully")
///   Log.error("Failed decoding response: \(error)")
///
/// In release builds, `debug` statements are compiled out; `error` is still logged
/// (without sensitive details) for crash triage. All logs are also sent to Crashlytics
/// for better debugging.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "CoveApp"
    private static let general = Logger(subsystem: subsystem, category: "general")
    private static let network = Logger(subsystem: subsystem, category: "network")

    /// Debug logging - only in DEBUG builds, minimal essential information
    /// Also logs to Crashlytics breadcrumbs for crash debugging
    static func debug(_ message: String, category: String = "general") {
        #if DEBUG
        if category == "network" {
            network.debug("\(message, privacy: .public)")
        } else {
            general.debug("\(message, privacy: .public)")
        }
        #endif
        
        // Always log to Crashlytics for crash debugging
        Crashlytics.crashlytics().log("[\(category.uppercased())] \(message)")
    }

    /// Error logging - always logged, essential for crash triage
    /// Also records as non-fatal error in Crashlytics
    static func error(_ message: String, category: String = "general") {
        if category == "network" {
            network.error("\(message, privacy: .public)")
        } else {
            general.error("\(message, privacy: .public)")
        }
        
        // Record as non-fatal error in Crashlytics
        let nsError = NSError(
            domain: "CoveApp.\(category.capitalized)",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        Crashlytics.crashlytics().record(error: nsError)
    }

    /// Critical debug logging - only for essential flow points
    /// Also logs to Crashlytics breadcrumbs
    static func critical(_ message: String, category: String = "general") {
        #if DEBUG
        if category == "network" {
            network.debug("🔴 \(message, privacy: .public)")
        } else {
            general.debug("🔴 \(message, privacy: .public)")
        }
        #endif
        
        // Always log to Crashlytics for crash debugging
        Crashlytics.crashlytics().log("🔴 [\(category.uppercased())] \(message)")
    }
    
    /// Network-specific logging with additional context
    /// - Parameters:
    ///   - message: The log message
    ///   - endpoint: The API endpoint being called
    ///   - method: The HTTP method used
    static func network(_ message: String, endpoint: String? = nil, method: String? = nil) {
        var fullMessage = message
        if let endpoint = endpoint {
            fullMessage += " | Endpoint: \(endpoint)"
        }
        if let method = method {
            fullMessage += " | Method: \(method)"
        }
        
        debug(fullMessage, category: "network")
    }
    
    /// Onboarding-specific logging with step context
    /// - Parameters:
    ///   - message: The log message
    ///   - step: The onboarding step being executed
    static func onboarding(_ message: String, step: String? = nil) {
        var fullMessage = message
        if let step = step {
            fullMessage += " | Step: \(step)"
        }
        
        debug(fullMessage, category: "onboarding")
    }
    
    /// Cove creation-specific logging with context
    /// - Parameters:
    ///   - message: The log message
    ///   - context: Additional context about the cove creation
    static func coveCreation(_ message: String, context: String? = nil) {
        var fullMessage = message
        if let context = context {
            fullMessage += " | Context: \(context)"
        }
        
        debug(fullMessage, category: "cove-creation")
    }
}
