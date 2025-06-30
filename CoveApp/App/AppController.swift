//
//  AppController.swift
//  Cove
//
//  Created by Ashley Dai on 4/28/25.
//

import SwiftUI
import FirebaseAuth

/// Enum representing all possible navigation routes in the app.
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
    case contacts
    case pluggingIn
    case profile
    case exploreFriends
    case friendRequests
    case yourInvites
    case home
    case membersList
    case eventPost(eventId: String)
    case feed(coveId: String)
}

/// AppController: Manages shared application state and business logic
/// - Handles authentication state
/// - Manages shared data between views
/// - Provides utility functions for data formatting and validation
/// - Singleton: Use AppController.shared or inject via .environmentObject
@MainActor
class AppController: ObservableObject {
    /// Singleton instance for global access
    static let shared = AppController()
    
    /// API base URL and login path (used for backend requests)
    private let apiBaseURL = "https://api.coveapp.co"
    private let apiLoginPath = "/login"
    
    /// Navigation path for NavigationStack
    @Published var path: [OnboardingRoute] = []
    /// Whether the user has completed onboarding (persisted)
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    /// Global error message for displaying alerts
    @Published var errorMessage: String = ""
    
    /// Shared CoveFeed instance for all cove feed and caching logic
    @Published var coveFeed = CoveFeed()
    
    /// Shared UpcomingFeed instance for all upcoming events and caching logic
    @Published var upcomingFeed = UpcomingFeed()
    
    /// Shared CalendarFeed instance for all calendar events (committed events) and caching logic
    @Published var calendarFeed = CalendarFeed()
    
    /// Shared ProfileModel instance for user profile data
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
        print("[AppController] Navigating to event: \(eventId)")
        path.append(.eventPost(eventId: eventId))
    }
    
    /**
     * Refreshes cove data across the app when needed.
     * This should be called after creating events or when data might be stale.
     */
    func refreshCoveData() {
        print("🔄 AppController: Cove data refresh requested")
        // This will be called by views that need to refresh cove data
        // For now, we'll rely on individual view models to handle their own refresh
    }
}
