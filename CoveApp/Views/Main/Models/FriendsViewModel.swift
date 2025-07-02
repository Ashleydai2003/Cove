//
//  FriendsViewModel.swift
//  Cove
//
//  Shared view model for friends list with caching and stale detection

import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false
    @Published var errorMessage: String?
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
        print("👥 FriendsViewModel initialized")
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        Friends.fetchFriends(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let resp):
                if self.nextCursor == nil {
                    // First page, replace existing data
                    self.friends = resp.friends
                } else {
                    // Append new friends to existing data
                    self.friends.append(contentsOf: resp.friends)
                }
                self.hasMore = resp.pagination.nextCursor != nil
                self.nextCursor = resp.pagination.nextCursor
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
            print("👥 FriendsViewModel: Loading friends data (\(reason))")
            loadNextPage()
        } else {
            print("👥 FriendsViewModel: ✅ Using fresh cached friends data (\(friends.count) friends) - NO NETWORK REQUEST")
        }
    }
} 