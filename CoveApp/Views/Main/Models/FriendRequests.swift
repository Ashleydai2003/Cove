//
//  FriendRequests.swift
//  Cove
//
//  Makes network calls necessary (/friend-requests, /send-friend-request, /resolve-friend-request) for friend requests screen.

import Foundation

// MARK: — DTOs

/// Incoming friend-request from GET /friend-requests
struct RequestDTO: Decodable, Identifiable {
    let id: String
    let sender: Sender
    let createdAt: Date
    
    struct Sender: Decodable {
        let id: String
        let name: String
        let profilePhotoUrl: URL?
    }

    // Conform to Identifiable
    var uuid: UUID { UUID(uuidString: id) ?? UUID() }
}

/// Response wrapper for GET /friend-requests
struct RequestsResponse: Decodable {
    let requests: [RequestDTO]
    let pagination: Pagination
    
    struct Pagination: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }
}

/// Response from POST /send-friend-request
struct SendRequestResponse: Decodable {
    let message: String
    let request: RequestRecord
    
    struct RequestRecord: Decodable {
        let id: String
        let senderId: String
        let recipientId: String
        let status: String
        let createdAt: Date
    }
}

/// Response from POST /resolve-friend-request
struct ResolveRequestResponse: Decodable {
    let message: String
    let friendship: FriendshipRecord?
    
    struct FriendshipRecord: Decodable {
        let id: String
        let user1Id: String
        let user2Id: String
        let status: String
        let createdAt: Date
    }
}

// MARK: — API

struct FriendRequests {
    
    /// Fetch pending requests (paginated)
    static func fetch(
        cursor: String? = nil,
        limit: Int = 10,
        completion: @escaping (Result<RequestsResponse, NetworkError>) -> Void
    ) {
        var params: [String: Any] = ["limit": limit]
        if let c = cursor { params["cursor"] = c }
        
        NetworkManager.shared.get(
            endpoint: "/friend-requests",
            parameters: params
        ) { (result: Result<RequestsResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    print("✅ fetch succeeded: \(resp.requests.count) requests, hasMore = \(resp.pagination.hasMore)")
                    completion(.success(resp))
                case .failure(let error):
                    print("❌ fetch failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Send a friend request to another user
    static func send(
        to recipientId: String,
        completion: @escaping (Result<SendRequestResponse, NetworkError>) -> Void
    ) {
        let body: [String: Any] = ["recipientId": recipientId]
        
        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: body
        ) { (result: Result<SendRequestResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    print("✅ send succeeded: message = '\(resp.message)', new request id = \(resp.request.id)")
                    completion(.success(resp))
                case .failure(let error):
                    print("❌ send failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Accept or reject an incoming request
    static func resolve(
        requestId: String,
        action: String, // "ACCEPT" or "REJECT"
        completion: @escaping (Result<ResolveRequestResponse, NetworkError>) -> Void
    ) {
        let body: [String: Any] = [
            "requestId": requestId,
            "action": action
        ]
        
        NetworkManager.shared.post(
            endpoint: "/resolve-friend-request",
            parameters: body
        ) { (result: Result<ResolveRequestResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    print("✅ resolve \(action.lowercased()) succeeded: message = '\(resp.message)'\(action == "ACCEPT" ? ", friendship id = \(resp.friendship?.id ?? "–")" : "")")
                    completion(.success(resp))
                case .failure(let error):
                    print("❌ resolve \(action.lowercased()) failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
}




