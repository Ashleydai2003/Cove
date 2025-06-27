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
    case yourInvites
    case home
    case membersList
    case eventPost(eventId: String)
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
    
    // TODO: we should actually probably store all models here 
    /// Profile model for storing user profile data
    @Published var profileModel = ProfileModel()
    
    /// Track the previous tab selection for navigation preservation
    @Published var previousTabSelection: Int = 1
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Navigation Helpers
    
    /**
     * Navigates to an event while preserving the current tab selection.
     * This ensures that when the user goes back from the event, they return to the same tab.
     * 
     * - Parameter eventId: The ID of the event to navigate to
     */
    func navigateToEvent(eventId: String) {
        // Navigate to the event
        // The previousTabSelection will be updated by HomeView's onChange(of: tabSelection)
        path.append(.eventPost(eventId: eventId))
    }
}
