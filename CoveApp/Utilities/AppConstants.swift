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

    /// WebSocket Configuration based on build configuration
    struct WebSocket {
        /// Returns the appropriate WebSocket URL based on build configuration
        static var socketURL: String {
            #if DEBUG
            // In Debug mode, use local Socket.io server
            return "ws://localhost:3001"
            #else
            // In Release mode, use secure WebSocket (WSS) for production
            return "wss://13.52.150.178:3001"
            #endif
        }
        
        /// Returns the secure WebSocket URL (WSS) for production
        static var secureSocketURL: String {
            #if DEBUG
            // In Debug mode, use local Socket.io server
            return "ws://localhost:3001"
            #else
            // In Release mode, use secure WebSocket (WSS) for production
            return "wss://13.52.150.178:3001"
            #endif
        }
        
        /// Current WebSocket environment for debugging
        static var environment: String {
            #if DEBUG
            return "Development (Local Socket.io)"
            #else
            return "Production (Secure WSS Socket.io)"
            #endif
        }
        
        /// Returns the appropriate WebSocket URL with protocol detection
        static var currentSocketURL: String {
            #if DEBUG
            return socketURL
            #else
            // In production, always use secure WSS
            return secureSocketURL
            #endif
        }
    }

}
