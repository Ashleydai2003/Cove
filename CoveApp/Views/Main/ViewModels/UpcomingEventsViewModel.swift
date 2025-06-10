//
//  UpcomingEventsViewModel.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

final class UpcomingEventsViewModel: BaseViewModel {
    
    @Published var events: [Event] = []
    @Published var groupedEvent: [Date: [Event]]?
    @Published var nextCursor: String?
    @Published var hasMore: Bool = false
    @Published var isLoading: Bool = false
    
    func fetchUpcomingEvents(cursor: String? = nil) {
        guard !isLoading else { return }
        
        isLoading = true
        let parameters: [String: Any] = [
            "limit": 10,
            "cursor": cursor as Any
        ]
        
        NetworkManager.shared.get(endpoint: "/calendar-events", parameters: parameters) { [weak self] (result: Result<EventsResponse, NetworkError>) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let response):
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
                print("Error fetching events: \(error.localizedDescription)")
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
