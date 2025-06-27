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
    
    private let pageSize = 5
    
    init() {
        print("📱 CoveModel initialized")
        // Don't fetch data in init to avoid publishing during view updates
    }
    
    func fetchCoveDetails() {
        guard !isLoading else { return }
        
        isLoading = true
        print("🔍 Fetching cove details...")
        
        // Get the first cove ID from UserDefaults
        let coveId: String? = (UserDefaults.standard.array(forKey: "user_cove_ids") as? [String])?.first
        guard let coveId else {
            print("❌ No cove ID found")
            errorMessage = "No cove ID found"
            isLoading = false
            return
        }
        
        NetworkManager.shared.get(endpoint: "/cove", parameters: ["coveId": coveId]) { [weak self] (result: Result<FeedCoveResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Cove details received: \(response.cove)")
                    self.cove = response.cove
                    // Reset events when fetching new cove
                    self.events = []
                    self.nextCursor = nil
                    self.hasMore = true
                    // Fetch first page of events
                    self.fetchEvents(coveId: coveId)
                case .failure(let error):
                    print("❌ Cove details error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func fetchEvents() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        print("🔍 Fetching events...")
        
        // Get the first cove ID from UserDefaults
        let coveId: String? = (UserDefaults.standard.array(forKey: "user_cove_ids") as? [String])?.first
        guard let coveId else {
            print("❌ No cove ID found")
            errorMessage = "No cove ID found"
            isLoading = false
            return
        }
        
        var params: [String: Any] = ["coveId": coveId, "limit": pageSize]
        if let cursor = nextCursor {
            params["cursor"] = cursor
        }
        
        NetworkManager.shared.get(endpoint: "/cove-events", parameters: params) { [weak self] (result: Result<CoveEventsResponse, NetworkError>) in
            guard let self = self else { return }
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
    
    func fetchEvents(coveId: String) {
        guard !isLoading && hasMore else { return }
        
        isLoading = true
        
        var parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]
        
        if let cursor = nextCursor {
            parameters["cursor"] = cursor
        }
        
        NetworkManager.shared.get(endpoint: "/cove-events", parameters: parameters) { [weak self] (result: Result<CoveEventsResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    // Append new events to existing array
                    self.events.append(contentsOf: response.events)
                    self.nextCursor = response.pagination.nextCursor
                    self.hasMore = response.pagination.hasMore
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadMoreEventsIfNeeded(currentEvent: CalendarEvent) {
        // If we're near the end of the current events array, load more
        if let lastEvent = events.last,
           lastEvent.id == currentEvent.id,
           hasMore && !isLoading {
            fetchEvents(coveId: cove?.id ?? "")
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
    
    struct CoverPhoto: Decodable {
        let id: String
        let url: String
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
