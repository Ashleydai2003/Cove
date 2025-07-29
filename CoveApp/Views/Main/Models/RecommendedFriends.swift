//
//  RecommendedFriends.swift
//  Cove
//
//  Makes network call to /recommended-friends endpoint; retrieves list of users who are recommended as friends.
//

import Foundation

// MARK: — Response Models

/// A single recommended friend entry returned from /recommended-friends
struct RecommendedFriendDTO: Decodable, Identifiable, ContentComparable {
    let id: String
    let name: String
    let profilePhotoUrl: URL?
    let sharedCoveCount: Int

    // Conform to Identifiable by using `id`
    var identifier: String { id }
    var uuid: UUID { UUID(uuidString: id) ?? UUID() }

    /// ContentComparable implementation - checks if meaningful content has changed
    func hasContentChanged(from other: RecommendedFriendDTO) -> Bool {
        return name != other.name ||
               profilePhotoUrl != other.profilePhotoUrl ||
               sharedCoveCount != other.sharedCoveCount
    }
}

/// Pagination information for /recommended-friends
struct RecommendedFriendsPagination: Decodable {
    let hasMore: Bool
    let nextCursor: String?
}

/// Full response from GET /recommended-friends
struct RecommendedFriendsResponse: Decodable {
    let users: [RecommendedFriendDTO]
    let pagination: RecommendedFriendsPagination
}

// MARK: — Service

/// RecommendedFriendsService: Fetches paginated recommended friends list via NetworkManager
class RecommendedFriends {
    /// Fetches a page of recommended friends
    /// - Parameters:
    ///   - cursor: ID of last user from previous page (for pagination)
    ///   - limit: Maximum number of items to return (defaults to 10, max 50)
    ///   - completion: Returns a RecommendedFriendsResponse on success, or NetworkError on failure
    static func fetchRecommendedFriends(
        cursor: String? = nil,
        limit: Int = 10,
        completion: @escaping (Result<RecommendedFriendsResponse, NetworkError>) -> Void
    ) {
        // Build query parameters
        var params: [String: Any] = ["limit": limit]
        if let cursor = cursor {
            params["cursor"] = cursor
        }

        // Call NetworkManager
        NetworkManager.shared.get(
            endpoint: "/recommended-friends",
            parameters: params
        ) { (result: Result<RecommendedFriendsResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
