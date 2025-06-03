//
//  UpcomingEventsViewModel.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

final class UpcomingEventsViewModel: BaseViewModel {
    
    @Published var events: [Event] = []
    @Published var groupedEvent: [Date: [Event]]?
    
    func fetchUpcomingEvents() {
        let response: EventsResponse = Bundle.main.decode("CoveEvents.json")
        
        groupedEvent = Dictionary(grouping: response.events ?? []) { event in
            event.eventDate
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
