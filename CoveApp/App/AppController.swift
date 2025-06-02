//
//  AppController.swift
//  Cove
//
//  Created by Ashley Dai on 4/28/25.
//

import SwiftUI
import FirebaseAuth

enum OnboardingRoute: Hashable {
    case enterPhoneNumber
    case otpVerify
    case adminVerify
    case userDetails
    case birthdate
    case userLocation
    case almaMater
    case moreAboutYou
    case hobbies
    case bio
    case profilePics
    case mutuals
    case pluggingIn
    case profile
    case exploreFriends
    case friendRequests
}

/// AppController: Manages shared application state and business logic
/// - Handles authentication state
/// - Manages shared data between views
/// - Provides utility functions for data formatting and validation
class AppController: ObservableObject {
    /// Singleton instance for global access
    static let shared = AppController()
    
    /// API base URL and login path
    private let apiBaseURL = "https://api.coveapp.co"
    private let apiLoginPath = "/login"
    
    /// Currently entered phone number
    @Published var path: [OnboardingRoute] = []
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var errorMessage: String = ""
    
    /// Private initializer to enforce singleton pattern
    private init() {}
}
