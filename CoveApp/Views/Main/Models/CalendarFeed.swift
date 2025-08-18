//
//  CalendarFeed.swift
//  Cove
//
//  Created by Ashley Dai on 6/29/25.
//

import SwiftUI

/// CalendarFeed: Manages the user's calendar events (committed events) with caching and lazy loading.
/// - Handles caching, preloading, and pagination for events the user has RSVP'd "GOING" to.
/// - Use a single shared instance (see AppController).
@MainActor
class CalendarFeed: ObservableObject {
    /// List of calendar events for the user (events they've committed to)
    @Published var events: [CalendarEvent] = []
    /// When set, CalendarView should navigate to this eventId and then clear it
    @Published var navigateToEventId: String?
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

    // TODO: Adjust cache duration as needed - currently set to 30 minutes
    private let cacheTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let pageSize = 10

    /// Checks if we have any cached data
    var hasCachedData: Bool {
        return lastFetched != nil // Empty array is still valid cached data
    }

    /// Checks if cache is stale (older than 30 minutes)
    var isCacheStale: Bool {
        guard let lastFetched = lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) > cacheTimeout
    }

    init() {
        Log.debug("CalendarFeed initialized")
    }

    /// Fetches calendar events from the backend, using cache if fresh.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    /// - Parameter completion: Optional completion handler called when the fetch operation completes
    func fetchCalendarEvents(forceRefresh: Bool = false, completion: (() -> Void)? = nil) {
        // Check if we have recent cached data and not forcing refresh
        if !forceRefresh && hasCachedData && !isCacheStale {
            Log.debug("CalendarFeed: using cached events – count=\(events.count)")
            completion?()
            return
        }

        guard !isLoading else { return }

        isLoading = true
        Log.debug("CalendarFeed: fetching events from backend…")

        var parameters: [String: Any] = [
            "limit": pageSize
        ]

        // Only include cursor if we're not refreshing and have one
        if !forceRefresh, let cursor = nextCursor {
            parameters["cursor"] = cursor
        }

        NetworkManager.shared.get(endpoint: "/calendar-events", parameters: parameters) { [weak self] (result: Result<CalendarEventsResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    Log.debug("CalendarFeed: events fetched – count=\(response.events?.count ?? 0)")

                    if forceRefresh || self.nextCursor == nil {
                        // First page or refresh, replace existing data
                        self.events = response.events ?? []
                    } else {
                        // Append new events to existing data
                        self.events.append(contentsOf: response.events ?? [])
                    }

                    self.hasMore = response.pagination?.hasMore ?? false
                    self.nextCursor = response.pagination?.nextCursor

                    // Prefetch cover photos
                    let urls = (response.events ?? []).compactMap { $0.coverPhoto?.url ?? $0.coveCoverPhoto?.url }
                    ImagePrefetcherUtil.prefetch(urlStrings: urls)

                    self.lastFetched = Date()

                    completion?()

                case .failure(let error):
                    Log.error("CalendarFeed fetch failed: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }

    /// Forces a refresh of calendar events data, bypassing cache.
    func refreshCalendarEvents(completion: (() -> Void)? = nil) {
        Log.debug("CalendarFeed: forcing refresh of events data")
        nextCursor = nil
        hasMore = true
        fetchCalendarEvents(forceRefresh: true, completion: completion)
    }

    /// Loads more events if the user scrolls to the end of the list.
    func loadMoreEventsIfNeeded() {
        if hasMore && !isLoading && nextCursor != nil {
            Log.debug("CalendarFeed: loading more events…")
            fetchCalendarEvents(forceRefresh: false)
        }
    }

    /// Fetches calendar events only if data is missing or stale (older than 30 minutes)
    func fetchCalendarEventsIfStale(completion: (() -> Void)? = nil) {
        if !hasCachedData || isCacheStale {
            let reason = !hasCachedData ? "no cached data" : "cache is stale"
            Log.debug("CalendarFeed: fetching events (\(reason))")
            fetchCalendarEvents(forceRefresh: false, completion: completion)
        } else {
            Log.debug("CalendarFeed: using cached fresh data count=\(events.count)")
            completion?()
        }
    }

    /// Gets events grouped by date for UI display
    var groupedEvents: [Date: [CalendarEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.eventDate)
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
