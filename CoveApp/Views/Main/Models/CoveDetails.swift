//
//  CoveDetails.swift
//  Cove
//
//  Created by Ananya Agarwal

import Foundation

struct CoveDetails: Decodable {
    let id: String
    let name: String
    let description: String?
    let location: String
    let createdAt: String
    let creator: CoveCreator?
    let coverPhoto: CoverPhoto?
    let stats: CoveStats?
}

struct CoveCreator: Decodable {
    let id: String?
    let name: String?
}

struct CoveStats: Decodable {
    let memberCount: Int?
    let eventCount: Int?
}

struct CoveDetailsResponse: Decodable {
    let cove: CoveDetails?
}
