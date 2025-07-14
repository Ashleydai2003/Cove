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
    
    /// Shared FriendsViewModel instance for friends list and caching logic
    @Published var friendsViewModel = FriendsViewModel()
    
    /// Shared RequestsViewModel instance for friend requests and caching logic
    @Published var requestsViewModel = RequestsViewModel()
    
    /// Shared MutualsViewModel instance for recommended friends and caching logic
    @Published var mutualsViewModel = MutualsViewModel()
    
    /// Shared InboxViewModel instance for cove invites and caching logic
    @Published var inboxViewModel = InboxViewModel()

    /// Controls visibility of the custom tab bar used in HomeView. Child views (e.g., FriendProfileView) can toggle this when they need full-screen presentation.
    @Published var showTabBar: Bool = true
    
    /// Whether to automatically show the inbox on home screen (when there are unopened invites)
    @Published var shouldAutoShowInbox = false
    
    /// Firebase Auth state listener handle so we can detach if ever needed
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Observe Firebase authentication state changes
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            Task { @MainActor in
                let isAuthenticated = (user != nil)
                if !isAuthenticated {
                    // User signed out – clear all cached data and reset UI
                    self.clearAllData()
                }
            }
        }
        
        // Bootstrap app UI based on any existing Firebase session.
        if Auth.auth().currentUser != nil {
            // Existing Firebase session detected.
            // If the user has already completed onboarding we start at the loading
            // screen that fetches all server data. Otherwise we remain in the
            // onboarding flow and wait for the backend login call to determine the
            // correct screen.
            if self.hasCompletedOnboarding {
                self.path = [.pluggingIn]
            } else {
                // User has NOT completed onboarding - sign them out to force fresh start
                // This prevents users from being stuck in onboarding when returning from background
                try? Auth.auth().signOut()
                self.clearAllData()
            }
        }
    }
    
    // MARK: - Initialization Methods
    
    /**
     * Initializes all data models after successful login/onboarding completion.
     * Called from PluggingYouIn after all other data has been loaded.
     */
    func initializeAfterLogin() {
        // Initialize inbox - it will call checkForAutoShowInbox when data loads
        inboxViewModel.initialize()
    }
    
    /// Called by InboxViewModel when invites are loaded to check if inbox should auto-show
    func checkForAutoShowInbox() {
        // Check if inbox should auto-show based on unopened invites
    }
    
    /**
     * Clears all data when user logs out.
     */
    func clearAllData() {
        // Clear all view model data
        coveFeed = CoveFeed()
        upcomingFeed = UpcomingFeed()
        calendarFeed = CalendarFeed()
        profileModel = ProfileModel()
        friendsViewModel = FriendsViewModel()
        requestsViewModel = RequestsViewModel()
        mutualsViewModel = MutualsViewModel()
        inboxViewModel.clear()
        
        // Reset UI state
        path = [] // ensure OnboardingFlow starts at LoginView after logout
        shouldAutoShowInbox = false
        isLoggedIn = false
        errorMessage = ""
    }
    
    // MARK: - Utility Methods
    
    /**
     * Refreshes cove data across the app when needed.
     * This should be called after creating events or when data might be stale.
     */
    func refreshCoveData() {
        // This will be called by views that need to refresh cove data
        // For now, we'll rely on individual view models to handle their own refresh
    }
    
    /**
     * Force refresh the cove feed after creating a new cove.
     * Call this after successfully creating a cove to update the UI immediately.
     */
    func refreshCoveFeedAfterCreation() {
        coveFeed.refreshUserCoves()
    }
    
    /**
     * Force refresh calendar and upcoming feeds after creating a new event.
     * Call this after successfully creating an event to update the UI immediately.
     */
    func refreshFeedsAfterEventCreation() {
        calendarFeed.refreshCalendarEvents()
        upcomingFeed.refreshUpcomingEvents()
    }
    
    /**
     * Force refresh a specific cove's events after creating an event in that cove.
     * Call this after successfully creating an event to update the cove view immediately.
     * Only refreshes events, not the cove header details.
     */
    func refreshCoveAfterEventCreation(coveId: String) {
        Log.critical("🔄 AppController: Refreshing cove events after event creation for coveId: \(coveId)")
        
        // Refresh the specific cove's events
        if let coveModel = coveFeed.coveModels[coveId] {
            Log.critical("✅ AppController: Found existing CoveModel for coveId: \(coveId), refreshing events")
            coveModel.refreshEvents()
        } else {
            Log.critical("🆕 AppController: Creating new CoveModel for coveId: \(coveId), refreshing events")
            let newModel = coveFeed.getOrCreateCoveModel(for: coveId)
            newModel.refreshEvents()
        }
        
        // Also refresh the cove feed to ensure UI updates
        coveFeed.refreshUserCoves()
    }
}
