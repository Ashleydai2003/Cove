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
                switch result {
                case .success:
                    () // No action needed
                case .failure(let error):
                    var reverted = self.pendingRequests
                    reverted.remove(userId)
                    withAnimation { self.pendingRequests = reverted }
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
