//
//  CalendarEvent.swift
//  Cove
//  Created by Nesib Muhedin


import Foundation

// Model for /calendar-events API response
struct CalendarEvent: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let coveName: String
    let hostId: String
    let hostName: String
    let rsvpStatus: String?
    let createdAt: String
    let coverPhoto: CoverPhoto?
    
    var eventDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let fullDate = inputFormatter.date(from: date) else {
            // Return a default date if parsing fails
            return Date()
        }
        return fullDate
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: self.date) else {
            return "TBD"
        }
        
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: self.date) else {
            return "TBD"
        }
        
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

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
    let coverPhoto: CoverPhoto?
    let isHost: Bool
    
    var eventDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let fullDate = inputFormatter.date(from: date) else {
            // Return a default date if parsing fails
            return Date()
        }
        return fullDate
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: self.date) else {
            return "TBD"
        }
        
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: self.date) else {
            return "TBD"
        }
        
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    struct Host: Decodable {
        let id: String
        let name: String
    }
    
    struct Cove: Decodable {
        let id: String
        let name: String
        let coverPhoto: CoverPhoto?
    }
}

struct CoverPhoto: Decodable {
    let id: String
    let url: String
}

struct Pagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}

struct EventsResponse: Decodable {
    let events: [Event]?
    let pagination: Pagination?
}

struct CalendarEventsResponse: Decodable {
    let events: [CalendarEvent]?
    let pagination: Pagination?
}

struct CreateEventResponse: Decodable {
    let message: String
    let event: CreatedEvent
}

struct CreatedEvent: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let createdAt: String
}
