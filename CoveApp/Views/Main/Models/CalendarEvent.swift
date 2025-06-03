//
//  CalendarEvent.swift
//  Cove
//  Created by Nesib Muhedin


import Foundation

struct Event: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String?
    let coveId: String
    let coveName: String?
    let hostId: String
    let hostName: String?
    let rsvpStatus: String?
    let createdAt: String
    let coverPhoto: CoverPhoto?
    
    var eventDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0) // "Z" = UTC
        
        guard let fullDate = inputFormatter.date(from: date) else {
            return Date()
        }
        // Strip time using Calendar in current timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let dateOnly = calendar.startOfDay(for: fullDate)
        print(dateOnly)
        return dateOnly
    }
}

struct CoverPhoto: Decodable {
    let id: String?
    let url: String?
    
}

struct Pagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
    
}

struct EventsResponse: Decodable {
    let events: [Event]?
    let pagination: Pagination?
}

struct CreateEventResponse: Decodable {
    let event: Event?
    let message: String?
}
