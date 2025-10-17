//
//  VendorFeed.swift
//  Cove
//
//  Vendor events feed manager
//

import SwiftUI
import Foundation

/// VendorFeed: Manages vendor events with caching and lazy loading.
/// - Handles caching, preloading, and pagination for vendor events.
/// - Use a single shared instance (see VendorController).
@MainActor
class VendorFeed: ObservableObject {
    /// List of vendor events
    @Published var events: [VendorEvent] = []
    /// Loading state for UI
    @Published var isLoading = false
    /// Error message for UI
    @Published var errorMessage: String?
    /// Last time events were fetched (for caching)
    @Published var lastFetched: Date?

    // TODO: Adjust cache duration as needed - currently set to 5 minutes
    private let cacheTimeout: TimeInterval = 5 * 60 // 5 minutes

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
        Log.debug("VendorFeed initialized")
    }

    /// Fetches vendor events from the backend, using cache if fresh.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    /// - Parameter completion: Optional completion handler called when the fetch operation completes
    func fetchVendorEvents(forceRefresh: Bool = false, completion: (() -> Void)? = nil) {
        // Check if we have recent cached data and not forcing refresh
        if !forceRefresh && hasCachedData && !isCacheStale {
            Log.debug("VendorFeed: using cached events count=\(events.count)")
            completion?()
            return
        }

        guard !isLoading else { return }

        isLoading = true
        Log.debug("VendorFeed: fetching events from backend…")

        VendorNetworkManager.shared.getVendorEvents { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let vendorEvents):
                    Log.debug("VendorFeed: events fetched count=\(vendorEvents.events.count)")
                    self.events = vendorEvents.events
                    self.lastFetched = Date()
                    completion?()

                case .failure(let error):
                    Log.error("VendorFeed fetch failed: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }

    /// Forces a refresh of vendor events data, bypassing cache.
    func refreshVendorEvents(completion: (() -> Void)? = nil) {
        Log.debug("VendorFeed: forcing refresh")
        fetchVendorEvents(forceRefresh: true, completion: completion)
    }

    /// Fetches vendor events only if data is missing or stale (older than 5 minutes)
    func fetchVendorEventsIfStale(completion: (() -> Void)? = nil) {
        if !hasCachedData || isCacheStale {
            let reason = !hasCachedData ? "no cached data" : "cache is stale"
            Log.debug("VendorFeed: fetching events (\(reason))")
            fetchVendorEvents(forceRefresh: false, completion: completion)
        } else {
            Log.debug("VendorFeed: using cached fresh data count=\(events.count)")
            completion?()
        }
    }

    /// Gets events grouped by date for UI display
    var groupedEvents: [Date: [VendorEvent]] {
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
