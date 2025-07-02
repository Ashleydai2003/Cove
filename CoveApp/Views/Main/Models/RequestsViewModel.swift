//
//  RequestsViewModel.swift
//  Cove
//
//  Shared view model for friend requests with caching and notification-based updates

import SwiftUI

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requests: [RequestDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false {
        didSet { if isLoading { loadingStart = Date() } }
    }
    @Published var errorMessage: String?
    @Published var lastFetched: Date?
    
    // TODO: Update requests list when push notifications are received for new friend requests
    // Friend requests should only refresh when:
    // 1. Initial load (no cached data)
    // 2. User performs pull-to-refresh
    // 3. Push notification received for new friend request
    // No automatic cache expiration needed since requests don't change frequently
    
    private let pageSize = 7
    private var loadingStart: Date?
    
    /// Checks if we have any cached data
    var hasCachedData: Bool {
        return lastFetched != nil // Empty array is still valid cached data
    }
    
    /// Friend requests don't expire automatically - only update on notifications
    var isCacheStale: Bool {
        return false // Never consider cache stale - only update on notifications or manual refresh
    }
    
    init() {
        print("📬 RequestsViewModel initialized")
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        FriendRequests.fetch(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let resp):
                if self.nextCursor == nil {
                    // First page, replace existing data
                    self.requests = resp.requests
                } else {
                    // Append new requests to existing data
                    self.requests.append(contentsOf: resp.requests)
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
            print("📬 RequestsViewModel: Loading requests data (\(reason))")
            loadNextPage()
        } else {
            print("📬 RequestsViewModel: ✅ Using fresh cached requests data (\(requests.count) requests) - NO NETWORK REQUEST")
        }
    }
    
    func accept(_ req: RequestDTO) {
        FriendRequests.resolve(requestId: req.id, action: "ACCEPT") { [weak self] result in
            switch result {
            case .success:
                self?.requests.removeAll { $0.id == req.id }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func reject(_ req: RequestDTO) {
        FriendRequests.resolve(requestId: req.id, action: "REJECT") { [weak self] result in
            switch result {
            case .success:
                self?.requests.removeAll { $0.id == req.id }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Call this method when a push notification is received for a new friend request
    /// TODO: Implement this when push notifications are added
    func handleNewRequestNotification() {
        print("📬 RequestsViewModel: New friend request notification received - refreshing data")
        // Force refresh to get the latest requests
        lastFetched = nil
        loadNextPage()
    }
} 