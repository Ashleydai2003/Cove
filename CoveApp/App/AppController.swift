//
//  AppController.swift
//  Cove
//
//  Created by Ashley Dai on 4/28/25.
//

import SwiftUI
import FirebaseAuth

/// Enum representing all possible navigation routes in the onboarding flow.
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
    
    /// Navigation path for onboarding NavigationStack
    @Published var path: [OnboardingRoute] = []
    /// Whether the user has completed onboarding (persisted)
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    /// Whether the user is logged in and data has been fetched
    @Published var isLoggedIn = false
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
    

    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Utility Methods
    
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
