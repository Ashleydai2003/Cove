//
//  ContactMatcher.swift
//  Cove
//

import Foundation
import Contacts
import FirebaseAuth

struct ContactMatcher {
    // MARK: - Configuration
    private static let matchPath = "/contacts"
    
    // MARK: - Models
    
    /// A user matched from your contacts
    struct MatchedUser: Decodable, Identifiable {
        let id: String        // your User.id
        let name: String      // User.name
        let imageURL: URL?    // S3.imageURL
    }
    
    // MARK: - Public API
    
    /// Runs the full flow: ask permission → read contacts → normalize → POST to `/contacts`
    /// - Parameter completion: returns `.success([MatchedUser])` or `.failure(Error)`
    static func matchContacts(completion: @escaping (Result<[MatchedUser], Error>) -> Void) {
        requestContactAccess { accessResult in
            switch accessResult {
            case .failure(let err):
                completion(.failure(err))
            case .success:
                fetchContacts { fetchResult in
                    switch fetchResult {
                    case .failure(let err):
                        completion(.failure(err))
                    case .success(let rawContacts):
                        let phones = normalize(rawContacts)
                        guard !phones.isEmpty else {
                            completion(.success([]))
                            return
                        }
                        postMatch(phones: phones, completion: completion)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: Permission
    
    private static func requestContactAccess(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, err in
            DispatchQueue.main.async {
                if granted {
                    completion(.success(()))
                } else {
                    completion(.failure(err ?? NSError(
                        domain: "ContactMatcher",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Contacts access denied"]
                    )))
                }
            }
        }
    }
    
    // MARK: - Step 2: Read contacts
    
    private struct RawContact {
        let phoneNumbers: [String]
    }
    
    private static func fetchContacts(_ completion: @escaping (Result<[RawContact], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let store = CNContactStore()
            let req = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor])
            var results = [RawContact]()
            do {
                try store.enumerateContacts(with: req) { raw, _ in
                    let phones = raw.phoneNumbers.map { $0.value.stringValue }
                    results.append(RawContact(phoneNumbers: phones))
                }
                DispatchQueue.main.async { completion(.success(results)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Step 3: Normalize to E.164
    
    private static func normalize(_ contacts: [RawContact]) -> [String] {
        let all = contacts.flatMap { $0.phoneNumbers }
        let set = Set(all.compactMap { raw in
            let digits = raw.filter(\.isNumber)
            switch digits.count {
            case 10:               return "+1" + digits
            case 11 where digits.first == "1": return "+" + digits
            default:               return nil
            }
        })
        return Array(set)
    }
    
    // MARK: - Step 4: POST via NetworkManager
    
    private static func postMatch(
        phones: [String],
        completion: @escaping (Result<[MatchedUser], Error>) -> Void
    ) {
        let token = UserDefaults.standard.string(forKey: "firebase_id_token") ?? ""
        let parameters: [String: Any] = ["phoneNumbers": phones]
        
        NetworkManager.shared.post(
            endpoint: matchPath,
            parameters: parameters
        ) { (result: Result<[MatchedUser], NetworkError>) in
            switch result {
            case .success(let users):
                completion(.success(users))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

