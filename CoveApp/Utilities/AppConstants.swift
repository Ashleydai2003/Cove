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
            // TODO: IMPORTANT make changes to use local development server instead
            // to do that we need to spin up a publically accessible S3 bucket for dev images
            // return "http://localhost:3001"
            return "https://api.coveapp.co"
            #else
            // In Release mode, use production server
            return "https://api.coveapp.co"
            #endif
        }
        
        /// Current environment name for debugging
        static var environment: String {
            #if DEBUG
            return "Development (Local)"
            #else
            return "Production"
            #endif
        }
    }
    
}
