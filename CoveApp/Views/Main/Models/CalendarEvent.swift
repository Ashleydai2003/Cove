//
//  CalendarEvent.swift
//  Cove
//
//  Refactored and documented for maintainability and best practices

import Foundation

// TODO: we should return less information, only the information needed

/// CalendarEvent: Represents a single event in a cove's feed or calendar.
/// - Used for event lists, event details, and event post views.
struct CalendarEvent: Decodable, Identifiable, ContentComparable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let memberCap: Int?
    let ticketPrice: Double?
    let coveId: String
    let coveName: String
    let coveCoverPhoto: CoverPhoto?
    let hostId: String
    let hostName: String
    let rsvpStatus: String?
    let goingCount: Int
    let pendingCount: Int?
    let createdAt: String
    let coverPhoto: CoverPhoto?

    // Memberwise initializer to preserve existing call sites
    init(
        id: String,
        name: String,
        description: String?,
        date: String,
        location: String,
        memberCap: Int? = nil,
        ticketPrice: Double? = nil,
        coveId: String,
        coveName: String,
        coveCoverPhoto: CoverPhoto?,
        hostId: String,
        hostName: String,
        rsvpStatus: String?,
        goingCount: Int,
        pendingCount: Int? = nil,
        createdAt: String,
        coverPhoto: CoverPhoto?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.date = date
        self.location = location
        self.memberCap = memberCap
        self.ticketPrice = ticketPrice
        self.coveId = coveId
        self.coveName = coveName
        self.coveCoverPhoto = coveCoverPhoto
        self.hostId = hostId
        self.hostName = hostName
        self.rsvpStatus = rsvpStatus
        self.goingCount = goingCount
        self.pendingCount = pendingCount
        self.createdAt = createdAt
        self.coverPhoto = coverPhoto
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, date, location, memberCap, ticketPrice, coveId, coveName, coveCoverPhoto, hostId, hostName, rsvpStatus, goingCount, pendingCount, createdAt, coverPhoto
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.date = try container.decode(String.self, forKey: .date)
        // Provide frontend defaults when limited fields are omitted
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? "RSVP to see location"
        self.memberCap = try container.decodeIfPresent(Int.self, forKey: .memberCap)
        self.ticketPrice = try container.decodeIfPresent(Double.self, forKey: .ticketPrice)
        self.coveId = try container.decodeIfPresent(String.self, forKey: .coveId) ?? ""
        self.coveName = try container.decodeIfPresent(String.self, forKey: .coveName) ?? ""
        self.coveCoverPhoto = try container.decodeIfPresent(CoverPhoto.self, forKey: .coveCoverPhoto)
        self.hostId = try container.decodeIfPresent(String.self, forKey: .hostId) ?? ""
        self.hostName = try container.decodeIfPresent(String.self, forKey: .hostName) ?? ""
        self.rsvpStatus = try container.decodeIfPresent(String.self, forKey: .rsvpStatus)
        self.goingCount = try container.decodeIfPresent(Int.self, forKey: .goingCount) ?? 0
        self.pendingCount = try container.decodeIfPresent(Int.self, forKey: .pendingCount)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? self.date
        self.coverPhoto = try container.decodeIfPresent(CoverPhoto.self, forKey: .coverPhoto)
    }

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

    /// ContentComparable implementation - checks if meaningful content has changed
    func hasContentChanged(from other: CalendarEvent) -> Bool {
        return name != other.name ||
               description != other.description ||
               date != other.date ||
               location != other.location ||
               memberCap != other.memberCap ||
               ticketPrice != other.ticketPrice ||
               rsvpStatus != other.rsvpStatus ||
               goingCount != other.goingCount ||
               pendingCount != other.pendingCount ||
               hostName != other.hostName ||
               coveName != other.coveName
    }
}

/// Event: Used for detailed event API responses (not just feed summaries)
struct Event: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String?
    let memberCap: Int?
    let ticketPrice: Double?
    let paymentHandle: String?
    let coveId: String?
    let host: Host?
    let cove: Cove?
    let rsvpStatus: String?
    let goingCount: Int?
    let pendingCount: Int?
    let rsvps: [EventRSVP]?
    let coverPhoto: CoverPhoto?
    let isHost: Bool?
    let useTieredPricing: Bool?
    let pricingTiers: [EventPricingTier]?
    
    // Custom CodingKeys to handle optional fields
    enum CodingKeys: String, CodingKey {
        case id, name, description, date, location, memberCap, ticketPrice, paymentHandle
        case coveId, host, cove, rsvpStatus, goingCount, pendingCount, rsvps
        case coverPhoto, isHost, useTieredPricing, pricingTiers
    }
    
    // Memberwise initializer for manual creation
    init(
        id: String,
        name: String,
        description: String?,
        date: String,
        location: String?,
        memberCap: Int?,
        ticketPrice: Double?,
        paymentHandle: String?,
        coveId: String?,
        host: Host?,
        cove: Cove?,
        rsvpStatus: String?,
        goingCount: Int?,
        pendingCount: Int?,
        rsvps: [EventRSVP]?,
        coverPhoto: CoverPhoto?,
        isHost: Bool?,
        useTieredPricing: Bool?,
        pricingTiers: [EventPricingTier]?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.date = date
        self.location = location
        self.memberCap = memberCap
        self.ticketPrice = ticketPrice
        self.paymentHandle = paymentHandle
        self.coveId = coveId
        self.host = host
        self.cove = cove
        self.rsvpStatus = rsvpStatus
        self.goingCount = goingCount
        self.pendingCount = pendingCount
        self.rsvps = rsvps
        self.coverPhoto = coverPhoto
        self.isHost = isHost
        self.useTieredPricing = useTieredPricing
        self.pricingTiers = pricingTiers
    }
    
    // Custom decoder to handle optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decode(String.self, forKey: .date)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        memberCap = try container.decodeIfPresent(Int.self, forKey: .memberCap)
        ticketPrice = try container.decodeIfPresent(Double.self, forKey: .ticketPrice)
        paymentHandle = try container.decodeIfPresent(String.self, forKey: .paymentHandle)
        coveId = try container.decodeIfPresent(String.self, forKey: .coveId)
        host = try container.decodeIfPresent(Host.self, forKey: .host)
        cove = try container.decodeIfPresent(Cove.self, forKey: .cove)
        rsvpStatus = try container.decodeIfPresent(String.self, forKey: .rsvpStatus)
        goingCount = try container.decodeIfPresent(Int.self, forKey: .goingCount)
        pendingCount = try container.decodeIfPresent(Int.self, forKey: .pendingCount)
        rsvps = try container.decodeIfPresent([EventRSVP].self, forKey: .rsvps)
        coverPhoto = try container.decodeIfPresent(CoverPhoto.self, forKey: .coverPhoto)
        isHost = try container.decodeIfPresent(Bool.self, forKey: .isHost)
        useTieredPricing = try container.decodeIfPresent(Bool.self, forKey: .useTieredPricing)
        pricingTiers = try container.decodeIfPresent([EventPricingTier].self, forKey: .pricingTiers)
    }

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
        let id: String?
        let name: String
    }
    /// Cove summary for the event
    struct Cove: Decodable {
        let id: String?
        let name: String?
        let coverPhoto: CoverPhoto?
    }
}

/// CoverPhoto: Used for both cove and event cover images
struct CoverPhoto: Decodable {
    let id: String
    let url: String
}

/// EventPricingTier: Represents a pricing tier for events with tiered pricing
struct EventPricingTier: Decodable {
    let id: String
    let tierType: String
    let price: Double
    let maxSpots: Int?
    let currentSpots: Int
    let sortOrder: Int
    let spotsLeft: Int?
    let isSoldOut: Bool?
}

/// EventRSVP: Represents an RSVP for an event
struct EventRSVP: Decodable, Identifiable {
    let id: String
    let status: String
    let userId: String
    let userName: String
    let profilePhotoUrl: URL?
    let createdAt: String
    let pricingTierId: String?
    let pricePaid: Double?
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

