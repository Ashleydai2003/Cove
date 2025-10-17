//
//  VendorEvent.swift
//  Cove
//
//  Vendor event model

import Foundation

struct VendorEvent: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let date: String  // Changed from Date to String to match API response
    let location: String
    let memberCap: Int?
    let ticketPrice: Double?
    let paymentHandle: String?
    let isPublic: Bool
    let vendorId: String
    let vendorName: String?
    let coverPhotoUrl: String?
    let useTieredPricing: Bool
    let pricingTiers: [PricingTier]
    let rsvpCounts: RSVPCounts
    let createdAt: String  // Changed from Date to String to match API response
    
    struct PricingTier: Codable, Hashable {
        let tierType: String
        let price: Double
        let maxSpots: Int?
        let sortOrder: Int
    }
    
    struct RSVPCounts: Codable, Hashable {
        let going: Int
        let maybe: Int
        let cantGo: Int
    }
    
    var eventDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date) ?? Date()
    }
}

struct VendorEventsResponse: Codable {
    let events: [VendorEvent]
}


