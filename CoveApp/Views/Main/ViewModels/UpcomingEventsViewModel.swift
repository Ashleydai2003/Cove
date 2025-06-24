//
//  UpcomingEventsViewModel.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

final class UpcomingEventsViewModel: BaseViewModel {
    
    @Published var events: [CalendarEvent] = []
    @Published var groupedEvent: [Date: [CalendarEvent]]?
    @Published var nextCursor: String?
    @Published var hasMore: Bool = false
    @Published var isLoading: Bool = false
    
    func fetchUpcomingEvents(cursor: String? = nil) {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Build parameters properly - only include cursor if it's not nil
        var parameters: [String: Any] = [
            "limit": 10
        ]
        
        if let cursor = cursor {
            parameters["cursor"] = cursor
        }
        
        print("🔍 UpcomingEventsViewModel: Calling /calendar-events with parameters: \(parameters)")
        
        NetworkManager.shared.get(endpoint: "/calendar-events", parameters: parameters) { [weak self] (result: Result<CalendarEventsResponse, NetworkError>) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let response):
                print("✅ UpcomingEventsViewModel: Successfully received response")
                print("📊 UpcomingEventsViewModel: Events count: \(response.events?.count ?? 0)")
                print("📄 UpcomingEventsViewModel: Pagination - hasMore: \(response.pagination?.hasMore ?? false), nextCursor: \(response.pagination?.nextCursor ?? "nil")")
                
                // Log each event for debugging
                if let events = response.events {
                    print("📋 UpcomingEventsViewModel: Event details:")
                    for (index, event) in events.enumerated() {
                        print("  Event \(index + 1):")
                        print("    ID: \(event.id)")
                        print("    Name: \(event.name)")
                        print("    Date: \(event.date)")
                        print("    Location: \(event.location)")
                        print("    CoveId: \(event.coveId)")
                        print("    CoveName: \(event.coveName)")
                        print("    HostId: \(event.hostId)")
                        print("    HostName: \(event.hostName)")
                        print("    RSVPStatus: \(event.rsvpStatus ?? "nil")")
                        print("    CoverPhoto: \(event.coverPhoto?.url ?? "nil")")
                        print("    ---")
                    }
                }
                
                if cursor == nil {
                    // First page, replace existing data
                    self.events = response.events ?? []
                } else {
                    // Append new events to existing data
                    self.events.append(contentsOf: response.events ?? [])
                }
                
                self.groupedEvent = Dictionary(grouping: self.events) { event in
                    event.eventDate
                }
                self.hasMore = response.pagination?.hasMore ?? false
                self.nextCursor = response.pagination?.nextCursor
                
            case .failure(let error):
                print("❌ UpcomingEventsViewModel: Error fetching events: \(error.localizedDescription)")
                // TODO: Handle error appropriately
            }
        }
    }
    
    func loadMoreEventsIfNeeded() {
        if hasMore, let cursor = nextCursor {
            fetchUpcomingEvents(cursor: cursor)
        }
    }
    
    func formattedDateWithOrdinal(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        // Step 1: Get day name and month name
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMMM" // e.g., "Friday April"

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
    
    func formattedTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = inputFormatter.date(from: dateString) {
            // Step 2: Format time only
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            outputFormatter.timeZone = TimeZone.current

            let timeString = outputFormatter.string(from: date)
            return timeString
        }
        
        return ""
    }
    
}
