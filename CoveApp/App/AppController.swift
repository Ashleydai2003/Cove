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
    case userDetails
    case birthdate
    case almaMater
    case hobbies
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
    
    /// Whether to automatically show the inbox on home screen (when there are unopened invites)
    @Published var shouldAutoShowInbox = false
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Initialization Methods
    
    /**
     * Initializes all data models after successful login/onboarding completion.
     * Called from PluggingYouIn after all other data has been loaded.
     */
    func initializeAfterLogin() {
        print("🔌 AppController: Initializing data after login...")
        
        // Initialize inbox - it will call checkForAutoShowInbox when data loads
        inboxViewModel.initialize()
    }
    
    /// Called by InboxViewModel when invites are loaded to check if inbox should auto-show
    func checkForAutoShowInbox() {
        print("🔌 AppController: checkForAutoShowInbox() called")
        print("🔌 AppController: Total invites: \(inboxViewModel.invites.count)")
        print("🔌 AppController: Unopened invites: \(inboxViewModel.unopenedInvites.count)")
        print("🔌 AppController: hasUnopenedInvites: \(inboxViewModel.hasUnopenedInvites)")
        print("🔌 AppController: Current shouldAutoShowInbox: \(shouldAutoShowInbox)")
        
        if inboxViewModel.hasUnopenedInvites {
            print("📮 AppController: Found unopened invites, setting shouldAutoShowInbox = true")
            shouldAutoShowInbox = true
            print("📮 AppController: shouldAutoShowInbox is now: \(shouldAutoShowInbox)")
        } else {
            print("📮 AppController: No unopened invites found")
        }
    }
    
    /**
     * Clears all data when user logs out.
     */
    func clearAllData() {
        print("🔌 AppController: Clearing all data on logout...")
        
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
        print("🔄 AppController: Cove data refresh requested")
        // This will be called by views that need to refresh cove data
        // For now, we'll rely on individual view models to handle their own refresh
    }
    
    /**
     * Force refresh the cove feed after creating a new cove.
     * Call this after successfully creating a cove to update the UI immediately.
     */
    func refreshCoveFeedAfterCreation() {
        print("🔄 AppController: Force refreshing cove feed after cove creation")
        coveFeed.refreshUserCoves()
    }
    
    /**
     * Force refresh calendar and upcoming feeds after creating a new event.
     * Call this after successfully creating an event to update the UI immediately.
     */
    func refreshFeedsAfterEventCreation() {
        print("🔄 AppController: Force refreshing feeds after event creation")
        calendarFeed.refreshCalendarEvents()
        upcomingFeed.refreshUpcomingEvents()
    }
    
    /**
     * Force refresh a specific cove's events after creating an event in that cove.
     * Call this after successfully creating an event to update the cove view immediately.
     * Only refreshes events, not the cove header details.
     */
    func refreshCoveAfterEventCreation(coveId: String) {
        print("🔄 AppController: Force refreshing cove \(coveId) events after event creation")
        if let coveModel = coveFeed.coveModels[coveId] {
            print("✅ AppController: Found existing CoveModel for cove \(coveId), calling refreshEvents()")
            coveModel.refreshEvents()
        } else {
            print("⚠️ AppController: No existing CoveModel found for cove \(coveId) - creating new one and triggering events refresh")
            let newModel = coveFeed.getOrCreateCoveModel(for: coveId)
            newModel.refreshEvents()
        }
    }
}
