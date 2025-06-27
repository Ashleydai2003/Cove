//
//  ContactMatcher.swift
//  Cove
//

import Foundation

/// Only exposes the `/contacts` call: you feed it E.164 numbers
struct ContactMatcher {
    private static let matchPath = "/contacts"

    // 1) Your existing user model
    struct MatchedUser: Decodable, Identifiable {
        let id: String
        let name: String
        let profilePhotoUrl: URL?
    }

    // 2) Add a wrapper that matches the JSON
    private struct ContactsResponse: Decodable {
        let contacts: [MatchedUser]
        let pagination: PaginationInfo
    }
    
    private struct PaginationInfo: Decodable {
        let hasMore: Bool
        let nextCursor: String?
    }

    /// POST the given E.164 phone numbers and decode the matched users.
    static func matchPhones(
        _ phones: [String],
        completion: @escaping (Result<[MatchedUser], Error>) -> Void
    ) {
        let parameters: [String: Any] = ["phoneNumbers": phones]

        // debug printing left as-is
        if let pretty = try? JSONSerialization
                          .data(withJSONObject: parameters, options: [.prettyPrinted]),
           let json = String(data: pretty, encoding: .utf8) {
            print("📞 POST /contacts body:\n\(json)")
        }

        // 3) Change the expected decoded type to the wrapper
        NetworkManager.shared.post(
            endpoint: matchPath,
            parameters: parameters
        ) { (result: Result<ContactsResponse, NetworkError>) in
            switch result {
            case .success(let wrapper):
                // 4) Extract the array and pass it along
                completion(.success(wrapper.contacts))

            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}




