//
//  Friends.swift
//  Cove
//
//  This file is the service/data model for fetching and caching the user's friends list.
//  
//  Why do we have both Friends (service) and FriendsViewModel (UI/view model)?
//  - Friends.swift is responsible for network calls, in-memory caching, and exposing data.
//  - FriendsViewModel is an ObservableObject that manages UI state (loading, errors, pagination) and updates the SwiftUI view.
//  - This separation keeps the code clean, testable, and scalable.
//  - If you used only Friends.swift, you would lose SwiftUI reactivity and mix service logic with UI state.
//  - Best practice: use Friends.swift for data/service, and FriendsViewModel for UI/view logic.
//
//  If you want to merge them, you could, but you would lose the benefits of clean architecture and reactivity.
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
    /// In-memory cache of the last fetched friends list
    private static var cachedFriends: [FriendDTO] = []
    private static var cachedPagination: FriendsPagination? = nil

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
                if cursor == nil {
                    // First page, replace cache
                    cachedFriends = response.friends
                } else {
                    // Append to cache
                    cachedFriends.append(contentsOf: response.friends)
                }
                cachedPagination = response.pagination
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Returns the cached friends list
    static var friendsCache: [FriendDTO] { cachedFriends }
    /// Clears the cached friends list
    static func clearCache() {
        cachedFriends = []
        cachedPagination = nil
    }
}
