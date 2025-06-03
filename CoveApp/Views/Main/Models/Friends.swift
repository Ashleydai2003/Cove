//
//  Friends.swift
//  Cove
//
//  Makes network call to /friends endpoint; retrieves list of user's friends.
//

import Foundation

// MARK: — Response Models

/// A single friend entry returned from /friends
struct FriendDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let profilePhotoUrl: URL?
    let friendshipId: String
    let createdAt: Date

    // Conform to Identifiable by using `friendshipId`
    var identifier: String { friendshipId }
    var uuid: UUID { UUID(uuidString: friendshipId) ?? UUID() }
}

/// Pagination information for /friends
struct FriendsPagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}

/// Full response from GET /friends
struct FriendsResponse: Decodable {
    let friends: [FriendDTO]
    let pagination: FriendsPagination
}

// MARK: — Service

/// FriendsService: Fetches paginated friends list via NetworkManager
class Friends {
    /// Fetches a page of friends
    /// - Parameters:
    ///   - cursor: ID of last friendship from previous page (for pagination)
    ///   - limit: Maximum number of items to return (defaults to 10, max 50)
    ///   - completion: Returns a FriendsResponse on success, or NetworkError on failure
    static func fetchFriends(
        cursor: String? = nil,
        limit: Int = 10,
        completion: @escaping (Result<FriendsResponse, NetworkError>) -> Void
    ) {
        // Build query parameters
        var params: [String: Any] = ["limit": limit]
        if let cursor = cursor {
            params["cursor"] = cursor
        }

        // Call NetworkManager
        NetworkManager.shared.get(
            endpoint: "/friends",
            parameters: params
        ) { (result: Result<FriendsResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
