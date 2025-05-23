//
//  ContactMatcher.swift
//  Cove
//

import Foundation

/// Only exposes the `/contacts` call: you feed it E.164 numbers
struct ContactMatcher {
    private static let matchPath = "/contacts"

    struct MatchedUser: Decodable, Identifiable {
        let id: String
        let name: String
        let phone: String
        let profilePhotoUrl: URL?
    }

    /// POST the given E.164 phone numbers and decode the matched users.
    static func matchPhones(
        _ phones: [String],
        completion: @escaping (Result<[MatchedUser], Error>) -> Void
    ) {
        let parameters: [String: Any] = ["phoneNumbers": phones]

        // debug
        if let pretty = try? JSONSerialization
                          .data(withJSONObject: parameters, options: [.prettyPrinted]),
           let json = String(data: pretty, encoding: .utf8) {
            print("📞 POST /contacts body:\n\(json)")
        }

        NetworkManager.shared.post(
            endpoint: matchPath,
            parameters: parameters
        ) { (result: Result<[MatchedUser], NetworkError>) in
            switch result {
            case .success(let users): completion(.success(users))
            case .failure(let err):    completion(.failure(err))
            }
        }
    }
}



