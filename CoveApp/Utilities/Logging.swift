import Foundation
import os

/// Simple wrapper around Swift's os.Logger that silences logs in non-DEBUG builds
/// and provides convenient static helpers.
///
/// Usage:
///   Log.debug("Loaded profile successfully")
///   Log.error("Failed decoding response: \(error)")
///
/// In release builds, `debug` statements are compiled out; `error` is still logged
/// (without sensitive details) for crash triage.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "CoveApp"
    private static let general = Logger(subsystem: subsystem, category: "general")
    private static let network = Logger(subsystem: subsystem, category: "network")
    
    /// Debug logging - only in DEBUG builds, minimal essential information
    static func debug(_ message: String, category: String = "general") {
        #if DEBUG
        if category == "network" {
            network.debug("\(message, privacy: .public)")
        } else {
            general.debug("\(message, privacy: .public)")
        }
        #endif
    }
    
    /// Error logging - always logged, essential for crash triage
    static func error(_ message: String, category: String = "general") {
        if category == "network" {
            network.error("\(message, privacy: .public)")
        } else {
            general.error("\(message, privacy: .public)")
        }
    }
    
    /// Critical debug logging - only for essential flow points
    static func critical(_ message: String, category: String = "general") {
        #if DEBUG
        if category == "network" {
            network.debug("🔴 \(message, privacy: .public)")
        } else {
            general.debug("🔴 \(message, privacy: .public)")
        }
        #endif
    }
} 