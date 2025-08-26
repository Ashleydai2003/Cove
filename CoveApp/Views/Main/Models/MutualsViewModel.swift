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
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var pendingRequests: Set<String> = []
    @Published var lastFetched: Date?

    // Track request attempts to prevent rapid firing
    private var pendingRequestAttempts: Set<String> = []

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
        Log.debug("🔗 MutualsViewModel initialized")
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

                // Prefetch profile photos
                let urls = response.users.compactMap { $0.profilePhotoUrl?.absoluteString }
                ImagePrefetcherUtil.prefetch(urlStrings: urls)

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
            Log.debug("🔗 MutualsViewModel: Loading mutuals data (\(reason))")
            loadNextPage()
        } else {
            Log.debug("🔗 MutualsViewModel: ✅ Using fresh cached mutuals data (\(mutuals.count) mutuals) - NO NETWORK REQUEST")
        }
    }

    func sendFriendRequest(to userId: String) {
        Log.debug("🔗 MUTUALS: Sending friend request to \(userId)")

        // Prevent rapid-fire requests to the same user
        guard !pendingRequestAttempts.contains(userId) else {
            Log.debug("🔗 MUTUALS: Request already in progress for \(userId), ignoring")
            return
        }

        // Track this attempt
        pendingRequestAttempts.insert(userId)

        // Optimistic UI update by assigning NEW Set reference
        var newSet = pendingRequests
        newSet.insert(userId)
        withAnimation { pendingRequests = newSet }

        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: ["toUserIds": [userId]]
        ) { [weak self] (result: Result<SendRequestResponse, NetworkError>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Remove from pending attempts regardless of outcome
                self.pendingRequestAttempts.remove(userId)
                
                switch result {
                case .success:
                    Log.debug("🔗 MUTUALS: ✅ Friend request sent successfully to \(userId)")
                    // Keep optimistic UI state - request is now truly pending
                case .failure(let error):
                    Log.debug("🔗 MUTUALS: ❌ Friend request failed for \(userId): \(error.localizedDescription)")
                    
                    // Handle 409 conflict specifically - state is stale
                    if case .serverError(let statusCode) = error, statusCode == 409 {
                        Log.debug("🔗 MUTUALS: 409 conflict - refreshing state for \(userId)")
                        // Remove from pending since request already exists or they're already friends
                        var reverted = self.pendingRequests
                        reverted.remove(userId)
                        withAnimation { self.pendingRequests = reverted }
                        
                        // Force refresh all friend-related state to sync with backend
                        self.refreshAllFriendState()
                        
                        // Show user-friendly message instead of raw 409 error
                        self.errorMessage = "Request already sent or you're already friends"
                    } else {
                        // Other errors - revert optimistic update
                        var reverted = self.pendingRequests
                        reverted.remove(userId)
                        withAnimation { self.pendingRequests = reverted }
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// Refreshes all friend-related state when conflicts are detected
    private func refreshAllFriendState() {
        Log.debug("🔗 MUTUALS: Refreshing all friend state due to conflict")
        
        // Clear cache and refresh mutuals data
        self.lastFetched = nil
        self.loadNextPage()
        
        // Refresh friends list
        AppController.shared.friendsViewModel.lastFetched = nil
        AppController.shared.friendsViewModel.loadNextPage()
        
        // Refresh friend requests
        AppController.shared.requestsViewModel.lastFetched = nil
        AppController.shared.requestsViewModel.loadNextPage()
    }

    /// Smooth refresh that preserves the current list while fetching fresh data
    func refresh(completion: (() -> Void)? = nil) {
        guard !isRefreshing else { completion?(); return }
        isRefreshing = true
        nextCursor = nil
        hasMore = true
        // Do NOT clear `mutuals` to avoid jank/flicker
        RecommendedFriends.fetchRecommendedFriends(cursor: nil, limit: pageSize) { [weak self] result in
            guard let self = self else { completion?(); return }
            DispatchQueue.main.async {
                self.isRefreshing = false
                switch result {
                case .success(let response):
                    self.mutuals = response.users
                    self.hasMore = response.pagination.hasMore
                    self.nextCursor = response.pagination.nextCursor
                    self.lastFetched = Date()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                completion?()
            }
        }
    }
}
