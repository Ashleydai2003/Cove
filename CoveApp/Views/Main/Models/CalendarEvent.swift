//
//  CalendarEvent.swift
//  Cove
//
//  Refactored and documented for maintainability and best practices

import Foundation

// TODO: we should return less information, only the information needed 

/// CalendarEvent: Represents a single event in a cove's feed or calendar.
/// - Used for event lists, event details, and event post views.
struct CalendarEvent: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let coveName: String
    let coveCoverPhoto: CoverPhoto?
    let hostId: String
    let hostName: String
    let rsvpStatus: String?
    let goingCount: Int
    let createdAt: String
    let coverPhoto: CoverPhoto?
    
    /// Returns the event date as a Date object (or now if parsing fails)
    var eventDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return inputFormatter.date(from: date) ?? Date()
    }
    /// Returns the event date as a formatted string (e.g., "March 5, 2024")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.date) else { return "TBD" }
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    /// Returns the event time as a formatted string (e.g., "5:00 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.date) else { return "TBD" }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

/// Event: Used for detailed event API responses (not just feed summaries)
struct Event: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let host: Host
    let cove: Cove
    let rsvpStatus: String?
    let rsvps: [EventRSVP]
    let coverPhoto: CoverPhoto?
    let isHost: Bool
    
    var eventDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return inputFormatter.date(from: date) ?? Date()
        }
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.date) else { return "TBD" }
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.date) else { return "TBD" }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    /// Host info for the event
    struct Host: Decodable {
        let id: String
        let name: String
    }
    /// Cove summary for the event
    struct Cove: Decodable {
        let id: String
        let name: String
        let coverPhoto: CoverPhoto?
    }
}

/// CoverPhoto: Used for both cove and event cover images
struct CoverPhoto: Decodable {
    let id: String
    let url: String
}

/// Pagination info for event lists
struct Pagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}

/// API response for event lists
struct EventsResponse: Decodable {
    let events: [Event]?
    let pagination: Pagination?
}

/// API response for calendar event lists
struct CalendarEventsResponse: Decodable {
    let events: [CalendarEvent]?
    let pagination: Pagination?
}

/// API response for event creation
struct CreateEventResponse: Decodable {
    let message: String
    let event: CreatedEvent
}

/// CreatedEvent: Used for event creation responses
struct CreatedEvent: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let createdAt: String
}

/// RSVP info for an event
struct EventRSVP: Decodable {
    let id: String
    let status: String
    let userId: String
    let userName: String
    let profilePhotoID: String?
    let createdAt: String
}
