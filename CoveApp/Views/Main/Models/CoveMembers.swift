//
//  CoveMembers.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

/// A single cove member entry returned from /cove-members
struct CoveMember: Decodable, Identifiable, ContentComparable {
    let id: String
    let name: String
    let profilePhotoUrl: URL?
    let role: String
    let joinedAt: String
    
    /// Returns the joinedAt date as a Date object (or now if parsing fails)
    var joinedDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return inputFormatter.date(from: joinedAt) ?? Date()
    }
    
    /// ContentComparable implementation - checks if meaningful content has changed
    func hasContentChanged(from other: CoveMember) -> Bool {
        return name != other.name ||
               role != other.role ||
               profilePhotoUrl != other.profilePhotoUrl ||
               joinedAt != other.joinedAt
    }
}

/// Pagination information for /cove-members
struct CoveMembersPagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}

/// Response for /cove-members API
struct CoveMembersResponse: Decodable {
    let members: [CoveMember]
    let pagination: CoveMembersPagination
}
