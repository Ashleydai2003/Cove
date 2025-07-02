//
//  CoveMembers.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

/// A single cove member entry returned from /cove-members
struct CoveMember: Decodable, Identifiable {
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
