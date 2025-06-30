//
//  CoveFeedModel.swift
//  Cove
//
//  Created by Ashley Dai on 6/29/25.
//

import SwiftUI

/// CoveFeed: Manages the list of user's coves and per-cove feed models.
/// - Handles caching, preloading, and per-cove view model storage.
/// - Use a single shared instance (see AppController).
@MainActor
class CoveFeed: ObservableObject {
    /// List of coves the user is a member of (summary info)
    @Published var userCoves: [Cove] = []
    /// The currently selected cove ID (for UI state)
    @Published var selectedCoveId: String?
    /// Last time user coves were fetched (for caching)
    @Published var lastFetchTime: Date?
    /// Loading state for UI
    @Published var isLoading = false
    /// Error message for UI
    @Published var errorMessage: String?
    
    // MARK: - Cancellation Support
    private var isCancelled: Bool = false
    
    /// Dictionary of per-cove feed models (for caching and instant transitions)
    @Published var coveModels: [String: CoveModel] = [:]
    
    init() {
        print("📱 CoveFeed initialized")
    }
    
    /// Cancels any ongoing requests and resets loading states.
    func cancelRequests() {
        print("🛑 CoveFeed: cancelRequests called - cancelling all tasks")
        isCancelled = true
        isLoading = false
    }
    
    /// Resets the cancellation flag when starting new requests.
    private func resetCancellationFlag() {
        isCancelled = false
    }
    
    /// Sets the user coves directly (used when fetched during onboarding).
    /// This bypasses the loading state and cache checks.
    func setUserCoves(_ coves: [Cove]) {
        print("📱 CoveFeed: Setting user coves directly (\(coves.count) coves)")
        self.userCoves = coves
        self.lastFetchTime = Date()
        
        // Set the first cove as selected if none is selected
        if self.selectedCoveId == nil && !coves.isEmpty {
            self.setSelectedCove(id: coves[0].id)
        }
    }
    
    /// Fetches user coves from the backend, using cache if fresh.
    /// - Parameter completion: Optional completion handler called when the fetch operation completes
    func fetchUserCoves(completion: (() -> Void)? = nil) {
        // Check if we have recent cached data
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < 300, // 5 minutes cache
           !userCoves.isEmpty {
            print("📱 CoveFeed: Using cached user coves data (", userCoves.count, ")")
            completion?()
            return
        }
        
        guard !isLoading else { return }
        
        resetCancellationFlag()
        isLoading = true
        print("🔍 CoveFeed: Fetching user coves from backend...")
        
        NetworkManager.shared.get(endpoint: "/user-coves") { [weak self] (result: Result<UserCovesResponse, NetworkError>) in
            guard let self = self else { return }
            
            // Check if request was cancelled
            guard !self.isCancelled else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ CoveFeed: User coves fetched successfully: \(response.coves.count) coves")
                    self.userCoves = response.coves
                    self.lastFetchTime = Date()
                    
                    // Set the first cove as selected if none is selected
                    if self.selectedCoveId == nil && !response.coves.isEmpty {
                        self.setSelectedCove(id: response.coves[0].id)
                    }
                    
                    completion?()
                    
                case .failure(let error):
                    print("❌ CoveFeed: User coves fetch failed: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }
    
    /// Forces a refresh of user coves data, bypassing cache.
    func refreshUserCoves(completion: (() -> Void)? = nil) {
        print("🔄 CoveFeed: Forcing refresh of user coves data")
        lastFetchTime = nil
        fetchUserCoves(completion: completion)
    }
    
    /// Gets the first cove ID from the user's coves (for default selection).
    func getFirstCoveId() -> String? {
        return userCoves.first?.id
    }
    
    /// Gets a specific cove by ID.
    func getCove(by id: String) -> Cove? {
        return userCoves.first { $0.id == id }
    }
    
    /// Sets the selected cove ID (for UI state).
    func setSelectedCove(id: String) {
        selectedCoveId = id
    }
    
    /// Gets the currently selected cove, or the first cove if none is selected.
    func getSelectedCove() -> Cove? {
        if let selectedId = selectedCoveId {
            return getCove(by: selectedId)
        }
        return userCoves.first
    }
    
    /// Returns the CoveModel for a given coveId, creating it if needed.
    func getOrCreateCoveModel(for id: String) -> CoveModel {
        if let existing = coveModels[id] {
            return existing
        }
        let newModel = CoveModel()
        coveModels[id] = newModel
        return newModel
    }
    
    /// Preloads cove details in the background for instant transitions.
    func preloadCoveDetails(for id: String) {
        let model = getOrCreateCoveModel(for: id)
        model.fetchCoveDetailsIfStale(coveId: id)
    }
}

// MARK: - Response Models
/// Response for /user-coves API
struct UserCovesResponse: Decodable {
    let coves: [Cove]
}

/// Summary model for a cove (used in the feed list)
struct Cove: Decodable {
    let id: String
    let name: String
    let coverPhoto: CoverPhoto?
} 