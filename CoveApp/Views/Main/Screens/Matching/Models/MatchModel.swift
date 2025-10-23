//
//  MatchModel.swift
//  Cove
//
//  AI Matching System - Match Model
//

import Foundation

// MARK: - Match Data Structures
struct Match: Codable, Identifiable {
    let id: String
    let matchedUserId: String
    let score: Double
    let tierUsed: Int
    let matchedOn: [String]
    let relaxedConstraints: [String]
    let createdAt: String
    let expiresAt: String
    let groupSize: Int?
    let user: MatchedUser
    
    struct MatchedUser: Codable {
        let name: String?
        let age: Int?
        let almaMater: String?
        let bio: String?
        let gender: String?
        let profilePhotoUrl: String?
    }
}

struct MatchResponse: Codable {
    let hasMatch: Bool
    let match: Match?
}

// MARK: - Match Model
@MainActor
class MatchModel: ObservableObject {
    @Published var currentMatch: Match?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Load current match
    func load() {
        isLoading = true
        
        NetworkManager.shared.get(
            endpoint: "/match/current",
            parameters: nil
        ) { [weak self] (result: Result<MatchAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    if data.hasMatch, let matchData = data.match {
                        self?.currentMatch = Match(
                            id: matchData.id,
                            matchedUserId: matchData.matchedUserId,
                            score: matchData.score,
                            tierUsed: matchData.tierUsed,
                            matchedOn: matchData.matchedOn,
                            relaxedConstraints: matchData.relaxedConstraints,
                            createdAt: matchData.createdAt,
                            expiresAt: matchData.expiresAt,
                            groupSize: matchData.groupSize,
                            user: Match.MatchedUser(
                                name: matchData.user.name,
                                age: matchData.user.age,
                                almaMater: matchData.user.almaMater,
                                bio: matchData.user.bio,
                                gender: matchData.user.gender,
                                profilePhotoUrl: matchData.user.profilePhotoUrl
                            )
                        )
                    } else {
                        self?.currentMatch = nil
                    }
                case .failure(let error):
                    Log.error("failed to load current match: \(error)")
                    self?.errorMessage = "failed to load match"
                }
            }
        }
    }
    
    // MARK: - Accept match
    func acceptMatch(completion: @escaping (String?) -> Void) {
        guard let match = currentMatch else {
            completion(nil)
            return
        }
        
        isLoading = true
        
        NetworkManager.shared.post(
            endpoint: "/match/\(match.id)/accept",
            parameters: [:]
        ) { [weak self] (result: Result<AcceptMatchResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    // Clear current match
                    self?.currentMatch = nil
                    
                    Log.debug("match accepted, thread created: \(data.threadId)")
                    completion(data.threadId)
                case .failure(let error):
                    Log.error("failed to accept match: \(error)")
                    self?.errorMessage = "failed to accept match"
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Decline match
    func declineMatch(completion: @escaping (Bool) -> Void) {
        guard let match = currentMatch else {
            completion(false)
            return
        }
        
        isLoading = true
        
        NetworkManager.shared.post(
            endpoint: "/match/\(match.id)/decline",
            parameters: [:]
        ) { [weak self] (result: Result<AcceptMatchResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // Clear current match
                    self?.currentMatch = nil
                    
                    Log.debug("match declined")
                    completion(true)
                case .failure(let error):
                    Log.error("failed to decline match: \(error)")
                    self?.errorMessage = "failed to decline match"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Submit feedback
    func submitFeedback(matchedOn: [String], wasAccurate: Bool, completion: @escaping (Bool) -> Void) {
        guard let match = currentMatch else {
            completion(false)
            return
        }
        
        let body: [String: Any] = [
            "matchedOn": matchedOn,
            "wasAccurate": wasAccurate
        ]
        
        NetworkManager.shared.post(
            endpoint: "/match/\(match.id)/feedback",
            parameters: body
        ) { (result: Result<AcceptMatchResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Log.debug("match feedback submitted")
                    completion(true)
                case .failure(let error):
                    Log.error("failed to submit feedback: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Helper: Parse match from dictionary
    private func parseMatch(from dict: [String: Any]) throws -> Match {
        guard let id = dict["id"] as? String,
              let matchedUserId = dict["matchedUserId"] as? String,
              let score = dict["score"] as? Double,
              let tierUsed = dict["tierUsed"] as? Int,
              let matchedOn = dict["matchedOn"] as? [String],
              let relaxedConstraints = dict["relaxedConstraints"] as? [String],
              let createdAt = dict["createdAt"] as? String,
              let expiresAt = dict["expiresAt"] as? String,
              let userDict = dict["user"] as? [String: Any] else {
            throw MatchError.invalidResponse
        }
        
        let user = Match.MatchedUser(
            name: userDict["name"] as? String,
            age: userDict["age"] as? Int,
            almaMater: userDict["almaMater"] as? String,
            bio: userDict["bio"] as? String,
            gender: userDict["gender"] as? String,
            profilePhotoUrl: userDict["profilePhotoUrl"] as? String
        )
        
        let groupSize = dict["groupSize"] as? Int
        
        return Match(
            id: id,
            matchedUserId: matchedUserId,
            score: score,
            tierUsed: tierUsed,
            matchedOn: matchedOn,
            relaxedConstraints: relaxedConstraints,
            createdAt: createdAt,
            expiresAt: expiresAt,
            groupSize: groupSize,
            user: user
        )
    }
}

// MARK: - Match Errors
enum MatchError: Error, LocalizedError {
    case noCurrentMatch
    case invalidResponse
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .noCurrentMatch:
            return "no current match available"
        case .invalidResponse:
            return "invalid response from server"
        case .networkError(let message):
            return message
        }
    }
}

