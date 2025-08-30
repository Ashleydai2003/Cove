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
    case citySelection
    case profilePics
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

    /// Whether the user is logged in and data has been fetched
    @Published var isLoggedIn = false
    /// Global error message for displaying alerts
    @Published var errorMessage: String = ""

    /// Whether the current user has completed onboarding (persisted per user)
    /// Thread-safe access to UserDefaults for onboarding status
    var hasCompletedOnboarding: Bool {
        get {
            guard let userId = Auth.auth().currentUser?.uid else { return false }
            return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_\(userId)")
        }
        set {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            // UserDefaults is thread-safe, but ensure we're on main thread if called from UI
            if Thread.isMainThread {
                UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding_\(userId)")
            } else {
                DispatchQueue.main.sync {
                    UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding_\(userId)")
                }
            }
        }
    }

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
                } else {
                    // If we have an authenticated user but no path set (app was killed during onboarding),
                    // handle the navigation logic here
                    if self.path.isEmpty {
                        if self.hasCompletedOnboarding {
                            self.path = [.pluggingIn]
                        } else {
                            // Keep path empty to start from login, but user is authenticated
                            // The backend login call will determine the correct screen
                        }
                    }
                }
            }
        }

        // Bootstrap app UI based on any existing Firebase session.
        let currentUser = Auth.auth().currentUser
        if currentUser != nil {
            // Existing Firebase session detected.
            // If the user has already completed onboarding we start at the loading
            // screen that fetches all server data. Otherwise we start from the beginning
            // of the onboarding flow and let the backend login call determine the correct screen.
            if self.hasCompletedOnboarding {
                self.path = [.pluggingIn]
            } else {
                // User has NOT completed onboarding - start from the beginning
                // but keep them authenticated. The backend will determine the correct screen
                // based on their onboarding status when they go through login
                self.path = []
            }
        } else {
            // No existing Firebase session - start fresh
            self.path = []
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
        // Clear user-specific onboarding flag
        if let userId = Auth.auth().currentUser?.uid {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding_\(userId)")
        }

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
        Log.debug("AppController: Refreshing cove feed after creation")
        
        // Ensure we're on the main thread for UI updates
        DispatchQueue.main.async {
            self.coveFeed.refreshUserCoves()
        }
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

        // Note: Not calling coveFeed.refreshUserCoves() here to prevent race conditions
        // The cove events refresh above is sufficient for the cove view
    }

    /**
     * Force refresh a specific cove's posts after creating a post in that cove.
     * Call this after successfully creating a post to update the cove view immediately.
     * Only refreshes posts, not the cove header details.
     */
    func refreshCoveAfterPostCreation(coveId: String) {
        Log.critical("🔄 AppController: Refreshing cove posts after post creation for coveId: \(coveId)")

        // Refresh the specific cove's posts
        if let coveModel = coveFeed.coveModels[coveId] {
            Log.critical("✅ AppController: Found existing CoveModel for coveId: \(coveId), refreshing posts")
            coveModel.refreshPosts()
        } else {
            Log.critical("🆕 AppController: Creating new CoveModel for coveId: \(coveId), refreshing posts")
            let newModel = coveFeed.getOrCreateCoveModel(for: coveId)
            newModel.refreshPosts()
        }

        // Also refresh the cove feed to ensure UI updates
        coveFeed.refreshUserCoves()
    }
}
