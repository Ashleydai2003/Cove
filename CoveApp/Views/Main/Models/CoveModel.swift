//
//  CoveModel.swift
//  Cove
//
//  Refactored and documented for maintainability and best practices

import SwiftUI
import FirebaseAuth

/// CoveModel: Manages the details and events for a specific cove.
/// - Handles event pagination, caching, and error/loading state.
/// - Use one instance per cove (see CoveFeed).
@MainActor
class CoveModel: ObservableObject {
    /// Full details for the current cove
    @Published var cove: FeedCoveDetails?
    /// List of events for the current cove
    @Published var events: [CalendarEvent] = []
    /// List of posts for the current cove
    @Published var posts: [CovePost] = []
    /// List of members for the current cove
    @Published var members: [CoveMember] = []
    /// Cursor for event pagination
    @Published var nextCursor: String?
    /// Cursor for post pagination
    @Published var postsCursor: String?
    /// Cursor for member pagination
    @Published var membersCursor: String?
    /// Whether more events are available
    @Published var hasMore = true
    /// Whether more posts are available
    @Published var hasPostsMore = true
    /// Whether more members are available
    @Published var hasMembersMore = true
    /// Loading state for UI
    @Published var isLoading = false
    /// Loading state specifically for events refresh (separate from main loading)
    @Published var isRefreshingEvents = false
    /// Loading state specifically for posts refresh (separate from main loading)
    @Published var isRefreshingPosts = false
    /// Loading state specifically for cove details refresh (separate from main loading)
    @Published var isRefreshingCoveDetails = false
    /// Loading state specifically for members refresh
    @Published var isRefreshingMembers = false
    /// Error message for UI display
    @Published var errorMessage: String?
    /// Last time cove details were fetched (for caching)
    @Published var lastFetched: Date?
    /// Last time events were fetched (for separate caching)
    @Published var eventsLastFetched: Date?
    /// Last time posts were fetched (for separate caching)
    @Published var postsLastFetched: Date?
    /// Last time members were fetched (for separate caching)
    @Published var membersLastFetched: Date?

    // Cache timeouts
    private let coveDetailsCacheTimeout: TimeInterval = 5 * 60 * 60 // 5 hours for cove details
    private let eventsCacheTimeout: TimeInterval = 5 * 60 // 5 minutes for events
    private let postsCacheTimeout: TimeInterval = 5 * 60 // 5 minutes for posts
    private let membersCacheTimeout: TimeInterval = 30 * 60 // 30 minutes for members
    private let pageSize = 5

    /// Checks if we have complete data (both cove details and events)
    var hasCompleteData: Bool {
        return cove != nil && !events.isEmpty
    }
    /// Checks if we have any data at all (cove details, even without events)
    var hasAnyData: Bool {
        return cove != nil
    }

    /// Checks if we have any cached cove data
    var hasCachedData: Bool {
        return cove != nil && lastFetched != nil
    }

    /// Checks if we have any cached events data
    var hasCachedEvents: Bool {
        return eventsLastFetched != nil
    }

    /// Checks if we have any cached posts data
    var hasCachedPosts: Bool {
        return postsLastFetched != nil
    }

    /// Checks if we have any cached members data
    var hasCachedMembers: Bool {
        return membersLastFetched != nil
    }

    /// Checks if cove details cache is stale (older than cache timeout)
    var isCacheStale: Bool {
        guard let lastFetch = lastFetched else { return true }
        return Date().timeIntervalSince(lastFetch) > coveDetailsCacheTimeout
    }

    /// Checks if events cache is stale (older than cache timeout)
    var isEventsCacheStale: Bool {
        guard let lastFetch = eventsLastFetched else { return true }
        return Date().timeIntervalSince(lastFetch) > eventsCacheTimeout
    }

    /// Checks if posts cache is stale (older than cache timeout)
    var isPostsCacheStale: Bool {
        guard let lastFetch = postsLastFetched else { return true }
        return Date().timeIntervalSince(lastFetch) > postsCacheTimeout
    }

    /// Checks if members cache is stale (older than cache timeout)
    var isMembersCacheStale: Bool {
        guard let lastFetch = membersLastFetched else { return true }
        return Date().timeIntervalSince(lastFetch) > membersCacheTimeout
    }

    /// Checks if the current user is an admin of this cove
    var isCurrentUserAdmin: Bool {
        let currentUserId = Auth.auth().currentUser?.uid ?? AppController.shared.profileModel.userId
        guard !currentUserId.isEmpty else { return false }
        return members.first { $0.id == currentUserId }?.role.lowercased() == "admin"
    }

    init() {
        Log.debug("📱 CoveModel initialized")
    }

    /// Fetches cove details with caching support.
    /// Only fetches fresh data if cache is stale or no cached data exists.
    func fetchCoveDetails(coveId: String, forceRefresh: Bool = false) {
        if !forceRefresh && hasCachedData && !isCacheStale && cove?.id == coveId {
            Log.debug("📱 CoveModel: Using cached cove data")
            if events.isEmpty {
                Log.debug("📱 CoveModel: Cached cove data found, but no events - fetching events")
                fetchEvents(coveId: coveId)
            }
            return
        }
        guard !isLoading else { return }
        isLoading = true
        Log.debug("🔍 CoveModel: Fetching cove details for cove ID: \(coveId)")
        NetworkManager.shared.get(endpoint: "/cove", parameters: ["coveId": coveId]) { [weak self] (result: Result<FeedCoveResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Cove details received: \(response.cove)")
                    self.cove = response.cove
                    self.lastFetched = Date()
                    if forceRefresh || self.events.isEmpty {
                        self.events = []
                        self.nextCursor = nil
                        self.hasMore = true
                        self.fetchEvents(coveId: coveId)
                    }
                case .failure(let error):
                    Log.debug("❌ CoveModel: Cove details error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    /// Fetches events for the current cove.
    func fetchEvents() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID available")
            errorMessage = "No cove ID available"
            return
        }
        fetchEvents(coveId: coveId)
    }
    /// Fetches events for a specific cove ID (with pagination).
    func fetchEvents(coveId: String, forceRefresh: Bool = false) {
        // Check if we should use cached events data
        if !forceRefresh && hasCachedEvents && !isEventsCacheStale && !events.isEmpty {
            Log.debug("📱 CoveModel: ✅ Using fresh cached events data (\(events.count) events) - NO NETWORK REQUEST")
            return
        }

        guard !isLoading && hasMore else { return }
        isLoading = true
        Log.debug("🔍 CoveModel: Fetching events...")
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
                    let newEvents = response.events ?? []
                    Log.debug("✅ CoveModel: Events received: \(newEvents.count) events")
                    self.events.append(contentsOf: newEvents)
                    if let pagination = response.pagination {
                        self.hasMore = pagination.hasMore
                        self.nextCursor = pagination.nextCursor
                    } else {
                        // Unauthenticated limited response has no pagination
                        self.hasMore = false
                        self.nextCursor = nil
                    }
                    self.eventsLastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Events error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    /// Forces a refresh of both cove data and events, bypassing cache.
    func refreshCoveData() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID available for refresh")
            return
        }
        Log.debug("🔄 CoveModel: refreshCoveData() called for cove \(coveId) - forcing refresh with new data")
        fetchCoveDetails(coveId: coveId, forceRefresh: true)
    }

    /// Forces a refresh of only cove details (header info), bypassing cache.
    func refreshCoveDetails() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID available for cove details refresh")
            return
        }
        guard !isRefreshingCoveDetails else { return }

        Log.debug("🔄 CoveModel: Refreshing cove details only")
        isRefreshingCoveDetails = true
        lastFetched = nil // Clear cache

        NetworkManager.shared.get(endpoint: "/cove", parameters: ["coveId": coveId]) { [weak self] (result: Result<FeedCoveResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isRefreshingCoveDetails = false
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Cove details refresh completed: \(response.cove.name)")

                    // Use smart diffing to only update UI if content actually changed
                    updateIfChanged(
                        current: self.cove,
                        new: response.cove
                    ) {
                        self.cove = response.cove
                    }

                    self.lastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Cove details refresh error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Refreshes only the events data, keeping the cached cove details.
    func refreshEvents() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID found for events refresh")
            return
        }
        guard !isRefreshingEvents else { return }

        Log.critical("🔄 CoveModel: Refreshing events data for coveId: \(coveId)")
        isRefreshingEvents = true
        events = []
        nextCursor = nil
        hasMore = true
        eventsLastFetched = nil // Clear events cache

        let parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]

        NetworkManager.shared.get(endpoint: "/cove-events", parameters: parameters) { [weak self] (result: Result<CoveEventsResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isRefreshingEvents = false
                switch result {
                case .success(let response):
                    let refreshed = response.events ?? []
                    Log.debug("✅ CoveModel: Events refresh completed: \(refreshed.count) events")

                    // Use smart diffing to only update UI if events actually changed
                    updateIfChanged(
                        current: self.events,
                        new: refreshed
                    ) {
                        self.events = refreshed
                        if let pagination = response.pagination {
                            self.hasMore = pagination.hasMore
                            self.nextCursor = pagination.nextCursor
                        } else {
                            self.hasMore = false
                            self.nextCursor = nil
                        }
                    }

                    self.eventsLastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Events refresh error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    /// Fetches members for a specific cove ID (with pagination).
    func fetchCoveMembers(coveId: String, forceRefresh: Bool = false) {
        // Check if we should use cached members data
        if !forceRefresh && hasCachedMembers && !isMembersCacheStale && !members.isEmpty {
            Log.debug("📱 CoveModel: ✅ Using fresh cached members data (\(members.count) members) - NO NETWORK REQUEST")
            return
        }

        guard !isRefreshingMembers && hasMembersMore else { return }
        isRefreshingMembers = true

        Log.debug("🔍 CoveModel: Fetching members...")
        let parameters: [String: Any] = {
            var params = [
                "coveId": coveId,
                "limit": pageSize
            ]
            if let cursor = membersCursor {
                params["cursor"] = cursor
            }
            return params
        }()

        NetworkManager.shared.get(endpoint: "/cove-members", parameters: parameters) { [weak self] (result: Result<CoveMembersResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isRefreshingMembers = false
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Members received: \(response.members.count) members")

                    // Use smart diffing to only update UI if members actually changed
                    let newMembers = (self.membersCursor == nil) ? response.members : self.members + response.members
                    updateIfChanged(
                        current: self.members,
                        new: newMembers
                    ) {
                        if self.membersCursor == nil {
                            // First page, replace members
                            self.members = response.members
                        } else {
                            // Append to existing members
                            self.members.append(contentsOf: response.members)
                        }
                        self.hasMembersMore = response.pagination.hasMore
                        self.membersCursor = response.pagination.nextCursor
                    }

                    self.membersLastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Members error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Refreshes only the members data, keeping the cached cove details.
    func refreshMembers() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID found for members refresh")
            return
        }
        guard !isRefreshingMembers else { return }

        Log.debug("🔄 CoveModel: Refreshing members data only")
        members = []
        membersCursor = nil
        hasMembersMore = true
        membersLastFetched = nil // Clear members cache
        fetchCoveMembers(coveId: coveId, forceRefresh: true)
    }

    /// Loads more members if the user scrolls to the end of the list.
    func loadMoreMembersIfNeeded(currentMember: CoveMember) {
        if let lastMember = members.last,
           lastMember.id == currentMember.id,
           hasMembersMore && !isRefreshingMembers {
            guard let coveId = cove?.id else {
                Log.debug("❌ CoveModel: No cove ID available for loading more members")
                return
            }
            fetchCoveMembers(coveId: coveId)
        }
    }

    /// Loads more events if the user scrolls to the end of the list.
    func loadMoreEventsIfNeeded(currentEvent: CalendarEvent) {
        if let lastEvent = events.last,
           lastEvent.id == currentEvent.id,
           hasMore && !isLoading {
            guard let coveId = cove?.id else {
                Log.debug("❌ CoveModel: No cove ID available for loading more events")
                return
            }
            fetchEvents(coveId: coveId)
        }
    }

    /// Fetches posts for the current cove.
    func fetchPosts() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID available")
            errorMessage = "No cove ID available"
            return
        }
        fetchPosts(coveId: coveId)
    }

    /// Fetches posts for a specific cove ID (with pagination).
    func fetchPosts(coveId: String, forceRefresh: Bool = false) {
        // Check if we should use cached posts data
        if !forceRefresh && hasCachedPosts && !isPostsCacheStale && !posts.isEmpty {
            Log.debug("📱 CoveModel: ✅ Using fresh cached posts data (\(posts.count) posts) - NO NETWORK REQUEST")
            return
        }

        guard !isLoading && hasPostsMore else { return }
        isLoading = true
        Log.debug("🔍 CoveModel: Fetching posts...")
        var parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]
        if let cursor = postsCursor {
            parameters["cursor"] = cursor
        }
        NetworkManager.shared.get(endpoint: "/cove-posts", parameters: parameters) { [weak self] (result: Result<CovePostsResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Posts received: \(response.posts.count) posts")
                    self.posts.append(contentsOf: response.posts)
                    self.hasPostsMore = response.pagination.hasMore
                    self.postsCursor = response.pagination.nextCursor
                    self.postsLastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Posts error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Refreshes only the posts data, keeping the cached cove details.
    func refreshPosts() {
        guard let coveId = cove?.id else {
            Log.debug("❌ CoveModel: No cove ID found for posts refresh")
            return
        }
        guard !isRefreshingPosts else { return }

        Log.critical("🔄 CoveModel: Refreshing posts data for coveId: \(coveId)")
        isRefreshingPosts = true
        posts = []
        postsCursor = nil
        hasPostsMore = true
        postsLastFetched = nil // Clear posts cache

        let parameters: [String: Any] = [
            "coveId": coveId,
            "limit": pageSize
        ]

        NetworkManager.shared.get(endpoint: "/cove-posts", parameters: parameters) { [weak self] (result: Result<CovePostsResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isRefreshingPosts = false
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Posts refresh completed: \(response.posts.count) posts")

                    // Use smart diffing to only update UI if posts actually changed
                    updateIfChanged(
                        current: self.posts,
                        new: response.posts
                    ) {
                        self.posts = response.posts
                        self.hasPostsMore = response.pagination.hasMore
                        self.postsCursor = response.pagination.nextCursor
                    }

                    self.postsLastFetched = Date()
                case .failure(let error):
                    Log.debug("❌ CoveModel: Posts refresh error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Loads more posts if the user scrolls to the end of the list.
    func loadMorePostsIfNeeded(currentPost: CovePost) {
        if let lastPost = posts.last,
           lastPost.id == currentPost.id,
           hasPostsMore && !isLoading {
            guard let coveId = cove?.id else {
                Log.debug("❌ CoveModel: No cove ID available for loading more posts")
                return
            }
            fetchPosts(coveId: coveId)
        }
    }

    /// Toggles the like status for a specific post
    func togglePostLike(postId: String, completion: @escaping (Bool) -> Void) {
        Log.debug("🔄 CoveModel: Toggling like for post: \(postId)")
        
        let params: [String: Any] = [
            "postId": postId
        ]
        
        NetworkManager.shared.post(
            endpoint: "/toggle-post-like",
            parameters: params
        ) { [weak self] (result: Result<TogglePostLikeResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    Log.debug("✅ CoveModel: Post like toggled successfully: \(response)")
                    
                    // Update the post's like status in the posts array
                    if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                        // Create a new post with updated like status
                        let oldPost = self.posts[index]
                        let newPost = CovePost(
                            id: oldPost.id,
                            content: oldPost.content,
                            coveId: oldPost.coveId,
                            coveName: oldPost.coveName,
                            authorId: oldPost.authorId,
                            authorName: oldPost.authorName,
                            authorProfilePhotoUrl: oldPost.authorProfilePhotoUrl,
                            isLiked: response.action == "liked",
                            likeCount: response.likeCount,
                            createdAt: oldPost.createdAt
                        )
                        self.posts[index] = newPost
                    }
                    
                    completion(true)
                case .failure(let error):
                    Log.error("❌ CoveModel: Post like toggle failed: \(error)")
                    self.errorMessage = "Failed to toggle like: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    /// Fetches cove details only if data is missing or stale
    func fetchCoveDetailsIfStale(coveId: String) {
        if !hasCachedData || isCacheStale || cove?.id != coveId {
            fetchCoveDetails(coveId: coveId)
        } else {
            Log.debug("📱 CoveModel: Using fresh cached cove data")
            // Still check if events need fetching
            if !hasCachedEvents || isEventsCacheStale {
                let reason = !hasCachedEvents ? "no cached events" : "events cache is stale"
                Log.debug("📱 CoveModel: Fetching events (\(reason))")
                fetchEvents(coveId: coveId)
            }
            // Also check if posts need fetching
            if !hasCachedPosts || isPostsCacheStale {
                let reason = !hasCachedPosts ? "no cached posts" : "posts cache is stale"
                Log.debug("📱 CoveModel: Fetching posts (\(reason))")
                fetchPosts(coveId: coveId)
            }
            // Also check if members need fetching
            if !hasCachedMembers || isMembersCacheStale {
                let reason = !hasCachedMembers ? "no cached members" : "members cache is stale"
                Log.debug("📱 CoveModel: Fetching members (\(reason))")
                fetchCoveMembers(coveId: coveId)
            }
        }
    }
}

// MARK: - Response Models
/// Response for /cove API
struct FeedCoveResponse: Decodable {
    let cove: FeedCoveDetails
}
/// Full details for a cove (used in the feed header)
struct FeedCoveDetails: Decodable, ContentComparable {
    let id: String
    let name: String
    let description: String?
    let location: String
    let creator: Creator
    let coverPhoto: CoverPhoto?
    let stats: Stats

    /// ContentComparable implementation - checks if meaningful content has changed
    func hasContentChanged(from other: FeedCoveDetails) -> Bool {
        return name != other.name ||
               description != other.description ||
               location != other.location ||
               creator.name != other.creator.name ||
               stats.memberCount != other.stats.memberCount ||
               stats.eventCount != other.stats.eventCount ||
               coverPhoto?.url != other.coverPhoto?.url
    }

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
    let events: [CalendarEvent]?
    let pagination: Pagination?
    struct Pagination: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }
}

/// Response for /cove-posts API
struct CovePostsResponse: Decodable {
    let posts: [CovePost]
    let pagination: Pagination
    struct Pagination: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }
}

/// Response for /toggle-post-like API
struct TogglePostLikeResponse: Decodable {
    let message: String
    let action: String
    let likeCount: Int
}

