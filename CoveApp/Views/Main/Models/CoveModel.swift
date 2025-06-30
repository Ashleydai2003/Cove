import SwiftUI

// MARK: - View Model
@MainActor
class CoveModel: ObservableObject {
    @Published var cove: FeedCoveDetails?
    @Published var events: [CalendarEvent] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Caching Support
    @Published var lastFetchTime: Date?
    @Published var isCancelled: Bool = false
    
    private let pageSize = 5
    
    // MARK: - Computed Properties
    
    /**
     * Checks if we have complete data (both cove details and events)
     */
    var hasCompleteData: Bool {
        return cove != nil && !events.isEmpty
    }
    
    /**
     * Checks if we have any data at all (cove details, even without events)
     */
    var hasAnyData: Bool {
        return cove != nil
    }
    
    init() {
        print("📱 CoveModel initialized")
        // Don't fetch data in init to avoid publishing during view updates
    }
    
    /**
     * Cancels any ongoing requests and resets loading states.
     * This should be called when the view is dismissed.
     */
    func cancelRequests() {
        isCancelled = true
        isLoading = false
    }
    
    /**
     * Resets the cancellation flag when starting new requests.
     */
    private func resetCancellationFlag() {
        isCancelled = false
    }
    
    /**
     * Fetches cove details with caching support.
     * Only fetches fresh data if cache is stale or no cached data exists.
     * 
     * - Parameter coveId: The specific cove ID to fetch details for
     * - Parameter forceRefresh: Whether to bypass cache and force a fresh fetch
     */
    func fetchCoveDetails(coveId: String, forceRefresh: Bool = false) {
        // Check if we have recent cached data and not forcing refresh
        if !forceRefresh, 
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < 300, // 5 minutes cache
           cove != nil,
           cove?.id == coveId {
            print("📱 Using cached cove data")
            
            // If we have cached cove data but no events, fetch events
            if events.isEmpty {
                print("📱 Cached cove data found, but no events - fetching events")
                fetchEvents(coveId: coveId)
            }
            return
        }
        
        guard !isLoading else { return }
        
        resetCancellationFlag()
        isLoading = true
        print("🔍 Fetching cove details for cove ID: \(coveId)")
        
        NetworkManager.shared.get(endpoint: "/cove", parameters: ["coveId": coveId]) { [weak self] (result: Result<FeedCoveResponse, NetworkError>) in
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
                    print("✅ Cove details received: \(response.cove)")
                    self.cove = response.cove
                    self.lastFetchTime = Date()
                    
                    // Only reset events if this is a fresh fetch (not cached)
                    if forceRefresh || self.events.isEmpty {
                        self.events = []
                        self.nextCursor = nil
                        self.hasMore = true
                        // Fetch first page of events
                        self.fetchEvents(coveId: coveId)
                    }
                case .failure(let error):
                    print("❌ Cove details error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /**
     * Fetches events for the current cove.
     * This method uses the cove ID from the current cove object.
     */
    func fetchEvents() {
        guard let coveId = cove?.id else {
            print("❌ No cove ID available")
            errorMessage = "No cove ID available"
            return
        }
        
        fetchEvents(coveId: coveId)
    }
    
    func fetchEvents(coveId: String) {
        guard !isLoading && hasMore else { return }
        
        resetCancellationFlag()
        isLoading = true
        print("🔍 Fetching events...")
        
        var parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]
        
        if let cursor = nextCursor {
            parameters["cursor"] = cursor
        }
        
        NetworkManager.shared.get(endpoint: "/cove-events", parameters: parameters) { [weak self] (result: Result<CoveEventsResponse, NetworkError>) in
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
                    print("✅ Events received: \(response.events.count) events")
                    self.events.append(contentsOf: response.events)
                    self.hasMore = response.pagination.hasMore
                    self.nextCursor = response.pagination.nextCursor
                case .failure(let error):
                    print("❌ Events error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /**
     * Forces a refresh of cove data, bypassing cache.
     * This should be called when we know the data has changed (e.g., after creating an event).
     */
    func refreshCoveData() {
        guard let coveId = cove?.id else {
            print("❌ No cove ID available for refresh")
            return
        }
        fetchCoveDetails(coveId: coveId, forceRefresh: true)
    }
    
    /**
     * Refreshes only the events data, keeping the cached cove details.
     * This is useful when we know events have changed but cove details haven't.
     */
    func refreshEvents() {
        guard let coveId = cove?.id else {
            print("❌ No cove ID found for events refresh")
            return
        }
        
        print("🔄 Refreshing events data")
        events = []
        nextCursor = nil
        hasMore = true
        fetchEvents(coveId: coveId)
    }
    
    func loadMoreEventsIfNeeded(currentEvent: CalendarEvent) {
        // If we're near the end of the current events array, load more
        if let lastEvent = events.last,
           lastEvent.id == currentEvent.id,
           hasMore && !isLoading {
            guard let coveId = cove?.id else {
                print("❌ No cove ID available for loading more events")
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
struct FeedCoveResponse: Decodable {
    let cove: FeedCoveDetails
}

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

struct CoveEventsResponse: Decodable {
    let events: [CalendarEvent]
    let pagination: Pagination
    
    struct Pagination: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }
} 
