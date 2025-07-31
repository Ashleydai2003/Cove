//
//  UpcomingFeed.swift
//  Cove
//
//  Created by Ashley Dai on 6/29/25.
//

import SwiftUI

/// UpcomingFeed: Manages the user's upcoming events and posts with caching and lazy loading.
/// - Handles caching, preloading, and pagination for upcoming events and posts from all user's coves.
/// - Use a single shared instance (see AppController).
@MainActor
class UpcomingFeed: ObservableObject {
    /// List of upcoming events and posts for the user (extracted from feed items)
    @Published var items: [FeedItem] = []
    /// Cursor for event pagination
    @Published var nextCursor: String?
    /// Whether more events are available
    @Published var hasMore = true
    /// Loading state for UI
    @Published var isLoading = false
    /// Error message for UI
    @Published var errorMessage: String?
    /// Last time events were fetched (for caching)
    @Published var lastFetched: Date?

    // TODO: Adjust cache duration as needed - currently set to 5 minutes
    private let cacheTimeout: TimeInterval = 5 * 60 // 5 minutes
    private let pageSize = 10

    /// Checks if we have any cached data
    var hasCachedData: Bool {
        return lastFetched != nil // Empty array is still valid cached data
    }

    /// Checks if cache is stale (older than 5 minutes)
    var isCacheStale: Bool {
        guard let lastFetched = lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) > cacheTimeout
    }

    init() {
        Log.debug("UpcomingFeed initialized")
    }

    /// Fetches upcoming events from the backend, using cache if fresh.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    /// - Parameter completion: Optional completion handler called when the fetch operation completes
    func fetchUpcomingEvents(forceRefresh: Bool = false, completion: (() -> Void)? = nil) {
        // Check if we have recent cached data and not forcing refresh
        if !forceRefresh && hasCachedData && !isCacheStale {
            Log.debug("UpcomingFeed: using cached items count=\(items.count)")
            completion?()
            return
        }

        guard !isLoading else { return }

        isLoading = true
        Log.debug("UpcomingFeed: fetching events from backend…")

        var parameters: [String: Any] = [
            "limit": pageSize,
            "types": "event,post"
        ]

        // Only include cursor if we're not refreshing and have one
        if !forceRefresh, let cursor = nextCursor {
            parameters["cursor"] = cursor
        }

        NetworkManager.shared.get(endpoint: "/feed", parameters: parameters) { [weak self] (result: Result<FeedResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    // Use all feed items (both events and posts)
                    let feedItems = response.items
                    
                    Log.debug("UpcomingFeed: items fetched count=\(feedItems.count)")

                    if forceRefresh || self.nextCursor == nil {
                        // First page or refresh, replace existing data
                        self.items = feedItems
                    } else {
                        // Append new items to existing data
                        self.items.append(contentsOf: feedItems)
                    }

                    self.hasMore = response.pagination.hasMore
                    self.nextCursor = response.pagination.nextCursor

                    // Prefetch images for both events and posts
                    let urls = feedItems.compactMap { item -> String? in
                        switch item {
                        case .event(let event):
                            return event.coverPhoto?.url ?? event.coveCoverPhoto?.url
                        case .post(let post):
                            return post.authorProfilePhotoUrl
                        }
                    }
                    ImagePrefetcherUtil.prefetch(urlStrings: urls)

                    self.lastFetched = Date()

                    completion?()

                case .failure(let error):
                    Log.error("UpcomingFeed fetch failed: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }

    /// Forces a refresh of upcoming events data, bypassing cache.
    func refreshUpcomingEvents(completion: (() -> Void)? = nil) {
        Log.debug("UpcomingFeed: forcing refresh")
        nextCursor = nil
        hasMore = true
        fetchUpcomingEvents(forceRefresh: true, completion: completion)
    }

    /// Loads more events if the user scrolls to the end of the list.
    func loadMoreEventsIfNeeded() {
        if hasMore && !isLoading && nextCursor != nil {
            Log.debug("UpcomingFeed: loading more events…")
            fetchUpcomingEvents(forceRefresh: false)
        }
    }

    /// Fetches upcoming events only if data is missing or stale (older than 5 minutes)
    func fetchUpcomingEventsIfStale(completion: (() -> Void)? = nil) {
        if !hasCachedData || isCacheStale {
            let reason = !hasCachedData ? "no cached data" : "cache is stale"
            Log.debug("UpcomingFeed: fetching events (\(reason))")
            fetchUpcomingEvents(forceRefresh: false, completion: completion)
        } else {
            Log.debug("UpcomingFeed: using cached fresh data count=\(items.count)")
            completion?()
        }
    }

    /// Gets events grouped by date for UI display (for backward compatibility)
    var groupedEvents: [Date: [CalendarEvent]] {
        let events = items.compactMap { item -> CalendarEvent? in
            switch item {
            case .event(let event):
                return CalendarEvent(
                    id: event.id,
                    name: event.name,
                    description: event.description,
                    date: event.date,
                    location: event.location,
                    coveId: event.coveId,
                    coveName: event.coveName,
                    coveCoverPhoto: event.coveCoverPhoto,
                    hostId: event.hostId,
                    hostName: event.hostName,
                    rsvpStatus: event.rsvpStatus,
                    goingCount: event.goingCount,
                    createdAt: event.createdAt,
                    coverPhoto: event.coverPhoto
                )
            case .post:
                return nil
            }
        }
        return Dictionary(grouping: events) { event in
            event.eventDate
        }
    }

    /// Formats date with ordinal suffix (e.g., "Friday April 5th")
    func formattedDateWithOrdinal(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMMM"

        let daySuffix: String
        switch day {
        case 11...13:
            daySuffix = "th"
        default:
            switch day % 10 {
            case 1: daySuffix = "st"
            case 2: daySuffix = "nd"
            case 3: daySuffix = "rd"
            default: daySuffix = "th"
            }
        }

        return "\(formatter.string(from: date)) \(day)\(daySuffix)"
    }

    /// Formats time from date string (e.g., "5:00 PM")
    func formattedTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            outputFormatter.timeZone = TimeZone.current
            return outputFormatter.string(from: date)
        }

        return ""
    }
}
