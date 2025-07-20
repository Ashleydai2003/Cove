//
//  AppConstants.swift
//  Cove
//

import Foundation
import UIKit

struct AppConstants {

    static let SystemSize = UIScreen.main.bounds.size
    static let MainBundle = Bundle.main

    // MARK: - API Configuration

    /// API Configuration based on build configuration
    struct API {
        /// Returns the appropriate API base URL based on build configuration
        static var baseURL: String {
            #if DEBUG
            // In Debug mode (simulator), use local development server
            // ✅ Now using local development with MinIO for S3 storage
            return "http://localhost:3001"
            #else
            // In Release mode, use production server
            return "https://api.coveapp.co"
            #endif
        }

        /// Current environment name for debugging
        static var environment: String {
            #if DEBUG
            return "Development (Local Server + MinIO)"
            #else
            return "Production"
            #endif
        }
    }

    /// WebSocket Configuration
    struct WebSocket {
        /// Returns the WebSocket URL
        static var socketURL: String {
            // Always use production socket server since local development doesn't run socket server
            return "wss://socket.coveapp.co:3001"
        }
        
        /// Current WebSocket environment for debugging
        static var environment: String {
            return "Production (Secure WSS Socket.io)"
        }
    }

}
