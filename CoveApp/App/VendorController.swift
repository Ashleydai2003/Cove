//
//  VendorController.swift
//  Cove
//
//  Controller for vendor account state and navigation
//

import SwiftUI
import FirebaseAuth

/// Onboarding steps for vendor flow
enum VendorOnboardingStep: Hashable {
    case initial
    case phoneEntry
    case otpVerify
    case codeEntry
    case createOrganization
    case userDetails
    case complete
}

/// VendorController: Manages vendor application state and business logic
@MainActor
class VendorController: ObservableObject {
    /// Singleton instance for global access
    static let shared = VendorController()
    
    /// Navigation path for vendor onboarding NavigationStack
    @Published var path: [VendorOnboardingStep] = []
    
    /// Whether the vendor user is logged in and data has been fetched
    @Published var isLoggedIn = false
    
    /// Whether vendor is authenticated (Firebase)
    @Published var isAuthenticated = false
    
    /// Current vendor user from login response
    @Published var vendorUser: VendorUserLoginInfo?
    
    /// Global error message for displaying alerts
    @Published var errorMessage: String = ""
    
    /// New vendor code (when creating organization)
    @Published var newVendorCode: String?
    
    /// Current vendor user profile
    @Published var vendorProfile: VendorUserProfile?
    
    /// Trigger to refresh vendor events
    @Published var shouldRefreshEvents: Bool = false
    
    /// Vendor events feed manager
    @Published var vendorFeed = VendorFeed()
    
    /// Whether the current vendor user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get {
            guard let userId = Auth.auth().currentUser?.uid else { return false }
            return UserDefaults.standard.bool(forKey: "vendorHasCompletedOnboarding_\(userId)")
        }
        set {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            UserDefaults.standard.set(newValue, forKey: "vendorHasCompletedOnboarding_\(userId)")
        }
    }
    
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
                    // If we have an authenticated user
                    if self.hasCompletedOnboarding && self.path.isEmpty {
                        self.path = [.complete]
                        self.isLoggedIn = true
                    }
                }
            }
        }
        
        // Bootstrap app UI based on any existing Firebase session
        let currentUser = Auth.auth().currentUser
        if currentUser != nil {
            if self.hasCompletedOnboarding {
                self.path = [.complete]
                self.isLoggedIn = true
            } else {
                self.path = []
                self.isLoggedIn = false
            }
        } else {
            self.path = []
            self.isLoggedIn = false
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    /// Clear all cached data when user signs out
    func clearAllData() {
        isLoggedIn = false
        path = []
        vendorProfile = nil
        newVendorCode = nil
        vendorUser = nil
        isAuthenticated = false
    }
    
    /// Fetch vendor profile data
    func fetchVendorProfile() {
        print("🔵 VendorController: Fetching vendor profile...")
        VendorNetworkManager.shared.getVendorProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ VendorController: Profile fetched successfully!")
                    print("   - Name: \(response.vendorUser.name ?? "nil")")
                    print("   - Phone: \(response.vendorUser.phone)")
                    print("   - Role: \(response.vendorUser.role)")
                    print("   - VendorId: \(response.vendorUser.vendorId ?? "nil")")
                    if let vendor = response.vendorUser.vendor {
                        print("   - Organization: \(vendor.organizationName)")
                        print("   - City: \(vendor.city)")
                    } else {
                        print("   - No vendor organization associated")
                    }
                    self?.vendorProfile = response.vendorUser
                    self?.isLoggedIn = true
                case .failure(let error):
                    print("❌ VendorController: Error fetching vendor profile: \(error)")
                    print("   - Error description: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load profile"
                }
            }
        }
    }
    
    /// Refresh vendor events feed
    func refreshVendorEvents() {
        print("🔄 VendorController: Refreshing vendor events...")
        vendorFeed.refreshVendorEvents()
        shouldRefreshEvents.toggle() // Toggle to trigger refresh in VendorEventsView
    }
    
    /// Sign out vendor user
    func signOut() {
        do {
            try Auth.auth().signOut()
            clearAllData()
            // Switch back to user mode
            UserDefaults.standard.set("user", forKey: "activeAccountType")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
}

