//
//  CoveDetails.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

struct CoveMember: Decodable {
    let id: String
    let name: String
    let profilePhotoUrl: String?
    let role: String?
    let joinedAt: String?
}

struct CoveMembersResponse: Decodable {
    let members: [CoveMember]?
    let pagination: Pagination?
}
