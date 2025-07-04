//
//  MutualsViewModel.swift
//  Cove
//
//  Shared view model for recommended friends/mutuals with caching and stale detection

import SwiftUI

@MainActor
class MutualsViewModel: ObservableObject {
    @Published var mutuals: [RecommendedFriendDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingRequests: Set<String> = []
    @Published var lastFetched: Date?
    
    // TODO: Adjust cache duration as needed - currently set to 30 minutes
    private let cacheTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let pageSize = 10
    
    /// Checks if we have any cached data
    var hasCachedData: Bool {
        return lastFetched != nil // Empty array is still valid cached data
    }
    
    /// Checks if cache is stale (older than cache timeout)
    var isCacheStale: Bool {
        guard let lastFetched = lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) > cacheTimeout
    }
    
    init() {
        print("🔗 MutualsViewModel initialized")
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        RecommendedFriends.fetchRecommendedFriends(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                // Use smart diffing to only update UI if mutuals data actually changed
                let newMutuals = (self.nextCursor == nil) ? response.users : self.mutuals + response.users
                updateIfChanged(
                    current: self.mutuals,
                    new: newMutuals
                ) {
                    if self.nextCursor == nil {
                        // First page, replace existing data
                        self.mutuals = response.users
                    } else {
                        // Append new mutuals to existing data
                        self.mutuals.append(contentsOf: response.users)
                    }
                    self.hasMore = response.pagination.hasMore
                    self.nextCursor = response.pagination.nextCursor
                }
                
                self.lastFetched = Date()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Loads next page only if data is missing or stale
    func loadNextPageIfStale() {
        if !hasCachedData || isCacheStale {
            let reason = !hasCachedData ? "no cached data" : "cache is stale"
            print("🔗 MutualsViewModel: Loading mutuals data (\(reason))")
            loadNextPage()
        } else {
            print("🔗 MutualsViewModel: ✅ Using fresh cached mutuals data (\(mutuals.count) mutuals) - NO NETWORK REQUEST")
        }
    }
    
    func sendFriendRequest(to userId: String) {
        // Mark as pending immediately for better UX
        pendingRequests.insert(userId)
        
        // Make API call to send friend request
        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: ["toUserIds": [userId]]
        ) { [weak self] (result: Result<SendRequestResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Keep it as pending - the user will see it in their friend requests
                    print("✅ Friend request sent successfully to \(userId)")
                case .failure(let error):
                    // Remove from pending if the request failed
                    self?.pendingRequests.remove(userId)
                    self?.errorMessage = error.localizedDescription
                    print("❌ Failed to send friend request: \(error)")
                }
            }
        }
    }
} 