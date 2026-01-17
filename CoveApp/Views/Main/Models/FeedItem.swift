//
//  FeedItem.swift
//  Cove
//
//  Created by Assistant

import Foundation
// If needed, import CalendarEvent.swift for CoverPhoto type

// MARK: - Feed Item Models

/// Discriminated union for feed items (events and posts)
enum FeedItem: Decodable, Identifiable {
    case event(FeedEvent)
    case post(FeedPost)
    
    var id: String {
        switch self {
        case .event(let event): return event.id
        case .post(let post): return post.id
        }
    }
    
    // Custom decoding looks at `kind`
    private enum CodingKeys: String, CodingKey { 
        case kind, event, post, id, rank 
    }
    
    enum Kind: String, Decodable { 
        case event, post 
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .event:
            self = .event(try container.decode(FeedEvent.self, forKey: .event))
        case .post:
            self = .post(try container.decode(FeedPost.self, forKey: .post))
        }
    }
}

/// Feed event model (simplified for feed display)
struct FeedEvent: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let memberCap: Int?
    let ticketPrice: Double?
    let coveId: String?
    let coveName: String
    let coveCoverPhoto: CoverPhoto?
    let hostId: String?
    let hostName: String
    let rsvpStatus: String
    let goingCount: Int
    let createdAt: String
    let coverPhoto: CoverPhoto?
    
    var eventDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date) ?? Date()
    }
}

/// Feed post model (simplified for feed display)
struct FeedPost: Decodable, Identifiable {
    let id: String
    let content: String
    let coveId: String
    let coveName: String
    let authorId: String
    let authorName: String
    let authorProfilePhotoUrl: String?
    let isLiked: Bool
    let likeCount: Int
    let createdAt: String
    
    var postDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
}

// MARK: - Supporting Models
// (No CoverPhoto struct here; use the one from CalendarEvent.swift)

// MARK: - Feed Response

struct FeedResponse: Decodable {
    let items: [FeedItem]
    let pagination: FeedPagination
}

struct FeedPagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
} 