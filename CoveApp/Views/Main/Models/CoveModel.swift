//
//  CoveModel.swift
//  Cove
//
//  Refactored and documented for maintainability and best practices

import SwiftUI

/// CoveModel: Manages the details and events for a specific cove.
/// - Handles event pagination, caching, and error/loading state.
/// - Use one instance per cove (see CoveFeed).
@MainActor
class CoveModel: ObservableObject {
    /// Full details for the current cove
    @Published var cove: FeedCoveDetails?
    /// List of events for the current cove
    @Published var events: [CalendarEvent] = []
    /// Cursor for event pagination
    @Published var nextCursor: String?
    /// Whether more events are available
    @Published var hasMore = true
    /// Loading state for UI
    @Published var isLoading = false
    /// Error message for UI
    @Published var errorMessage: String?
    /// Last time cove details were fetched (for caching)
    @Published var lastFetchTime: Date?
    /// Whether requests have been cancelled (for cleanup)
    @Published var isCancelled: Bool = false
    private let pageSize = 5
    
    /// Checks if we have complete data (both cove details and events)
    var hasCompleteData: Bool {
        return cove != nil && !events.isEmpty
    }
    /// Checks if we have any data at all (cove details, even without events)
    var hasAnyData: Bool {
        return cove != nil
    }
    
    init() {
        print("📱 CoveModel initialized")
    }
    
    /// Cancels any ongoing requests and resets loading states.
    func cancelRequests() {
        isCancelled = true
        isLoading = false
    }
    /// Resets the cancellation flag when starting new requests.
    private func resetCancellationFlag() {
        isCancelled = false
    }
    /// Fetches cove details with caching support.
    /// Only fetches fresh data if cache is stale or no cached data exists.
    func fetchCoveDetails(coveId: String, forceRefresh: Bool = false) {
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < 300,
           cove != nil,
           cove?.id == coveId {
            print("📱 CoveModel: Using cached cove data")
            if events.isEmpty {
                print("📱 CoveModel: Cached cove data found, but no events - fetching events")
                fetchEvents(coveId: coveId)
            }
            return
        }
        guard !isLoading else { return }
        resetCancellationFlag()
        isLoading = true
        print("🔍 CoveModel: Fetching cove details for cove ID: \(coveId)")
        NetworkManager.shared.get(endpoint: "/cove", parameters: ["coveId": coveId]) { [weak self] (result: Result<FeedCoveResponse, NetworkError>) in
            guard let self = self else { return }
            guard !self.isCancelled else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    print("✅ CoveModel: Cove details received: \(response.cove)")
                    self.cove = response.cove
                    self.lastFetchTime = Date()
                    if forceRefresh || self.events.isEmpty {
                        self.events = []
                        self.nextCursor = nil
                        self.hasMore = true
                        self.fetchEvents(coveId: coveId)
                    }
                case .failure(let error):
                    print("❌ CoveModel: Cove details error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    /// Fetches events for the current cove.
    func fetchEvents() {
        guard let coveId = cove?.id else {
            print("❌ CoveModel: No cove ID available")
            errorMessage = "No cove ID available"
            return
        }
        fetchEvents(coveId: coveId)
    }
    /// Fetches events for a specific cove ID (with pagination).
    func fetchEvents(coveId: String) {
        guard !isLoading && hasMore else { return }
        resetCancellationFlag()
        isLoading = true
        print("🔍 CoveModel: Fetching events...")
        var parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]
        if let cursor = nextCursor {
            parameters["cursor"] = cursor
        }
        NetworkManager.shared.get(endpoint: "/cove-events", parameters: parameters) { [weak self] (result: Result<CoveEventsResponse, NetworkError>) in
            guard let self = self else { return }
            guard !self.isCancelled else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    print("✅ CoveModel: Events received: \(response.events.count) events")
                    self.events.append(contentsOf: response.events)
                    self.hasMore = response.pagination.hasMore
                    self.nextCursor = response.pagination.nextCursor
                case .failure(let error):
                    print("❌ CoveModel: Events error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    /// Forces a refresh of cove data, bypassing cache.
    func refreshCoveData() {
        guard let coveId = cove?.id else {
            print("❌ CoveModel: No cove ID available for refresh")
            return
        }
        fetchCoveDetails(coveId: coveId, forceRefresh: true)
    }
    /// Refreshes only the events data, keeping the cached cove details.
    func refreshEvents() {
        guard let coveId = cove?.id else {
            print("❌ CoveModel: No cove ID found for events refresh")
            return
        }
        print("🔄 CoveModel: Refreshing events data")
        events = []
        nextCursor = nil
        hasMore = true
        fetchEvents(coveId: coveId)
    }
    /// Loads more events if the user scrolls to the end of the list.
    func loadMoreEventsIfNeeded(currentEvent: CalendarEvent) {
        if let lastEvent = events.last,
           lastEvent.id == currentEvent.id,
           hasMore && !isLoading {
            guard let coveId = cove?.id else {
                print("❌ CoveModel: No cove ID available for loading more events")
                return
            }
            fetchEvents(coveId: coveId)
        }
    }
    /// Fetches cove details only if data is missing or stale (older than 5 minutes)
    func fetchCoveDetailsIfStale(coveId: String) {
        let needsRefresh = lastFetchTime == nil ||
            Date().timeIntervalSince(lastFetchTime!) > 300
        if !hasCompleteData || needsRefresh {
            fetchCoveDetails(coveId: coveId)
        }
    }
}

// MARK: - Response Models
/// Response for /cove API
struct FeedCoveResponse: Decodable {
    let cove: FeedCoveDetails
}
/// Full details for a cove (used in the feed header)
struct FeedCoveDetails: Decodable {
    let id: String
    let name: String
    let description: String?
    let location: String
    let creator: Creator
    let coverPhoto: CoverPhoto?
    let stats: Stats
    struct Creator: Decodable {
        let id: String
        let name: String
    }
    struct Stats: Decodable {
        let memberCount: Int
        let eventCount: Int
    }
}
/// Response for /cove-events API
struct CoveEventsResponse: Decodable {
    let events: [CalendarEvent]
    let pagination: Pagination
    struct Pagination: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }
} 
