//
//  SurveyModel.swift
//  Cove
//
//  AI Matching System - Survey Model
//

import Foundation

// MARK: - API Response Models
struct SurveyAPIResponse: Codable {
    let responses: [SurveyResponseData]
}

struct SurveyResponseData: Codable {
    let questionId: String
    let value: AnyCodable
    let isMustHave: Bool
}

struct IntentionAPIResponse: Codable {
    let message: String?
    let intention: IntentionData?
    let poolEntry: PoolEntryData?
    let hasIntention: Bool?
    let hasMatch: Bool?
}

struct IntentionData: Codable {
    let id: String
    let text: String
    let validUntil: String
    let status: String
}

struct PoolEntryData: Codable {
    let tier: Int
    let nextBatchEta: String
    let joinedAt: String?
}

struct MatchAPIResponse: Codable {
    let hasMatch: Bool
    let match: MatchData?
}

struct MatchData: Codable {
    let id: String
    let matchedUserId: String
    let score: Double
    let tierUsed: Int
    let matchedOn: [String]
    let relaxedConstraints: [String]
    let createdAt: String
    let expiresAt: String
    let groupSize: Int?
    let user: MatchedUserData
}

struct MatchedUserData: Codable {
    let name: String?
    let age: Int?
    let almaMater: String?
    let bio: String?
    let gender: String?
    let profilePhotoUrl: String?
}

struct ProfileAPIResponse: Codable {
    let profile: UserProfileData
}

struct UserProfileData: Codable {
    let city: String?
}

struct AcceptMatchResponse: Codable {
    let threadId: String
}

// MARK: - Survey Question Types
enum SurveyQuestionID: String, CaseIterable {
    case energySource = "energy_source"
    case groupSize = "group_size"
    case valuedTraits = "valued_traits"
    case idealConnection = "ideal_connection"
    case industry = "industry"
    case relationshipStatus = "relationship_status"
    case sexualOrientation = "sexual_orientation"
    case musicGenres = "music_genres"
    case drinkingHabits = "drinking_habits"
}

struct SurveyQuestion {
    let id: SurveyQuestionID
    let question: String
    let type: QuestionType
    let options: [String]
    let canBeMustHave: Bool
    let maxSelection: Int?
    
    enum QuestionType {
        case singleSelect
        case multiSelect
    }
}

struct SurveyResponse: Codable {
    let questionId: String
    let value: AnyCodable  // Can be String or [String]
    let isMustHave: Bool
    
    enum CodingKeys: String, CodingKey {
        case questionId, value, isMustHave
    }
}

// MARK: - AnyCodable wrapper for JSON encoding
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [String] {
            try container.encode(array)
        } else if let int = value as? Int {
            try container.encode(int)
        } else {
            try container.encodeNil()
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([String].self) {
            value = array
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else {
            value = ""
        }
    }
}

// MARK: - Survey Model
@MainActor
class SurveyModel: ObservableObject {
    @Published var responses: [SurveyQuestionID: (value: Any, isMustHave: Bool)] = [:]
    @Published var isComplete: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Survey questions definition
    let questions: [SurveyQuestion] = [
        SurveyQuestion(
            id: .energySource,
            question: "where do you get your energy?",
            type: .singleSelect,
            options: ["introvert—i recharge alone", "ambivert—somewhere in between", "extrovert—i recharge with people"],
            canBeMustHave: true,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .groupSize,
            question: "what's your ideal group size when hanging out?",
            type: .singleSelect,
            options: ["one-on-one or small group (2-3 people)", "medium group (5-8 people)", "large group (8+ people)", "i'm flexible; depends on activity"],
            canBeMustHave: true,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .valuedTraits,
            question: "what traits do you value most in people?",
            type: .multiSelect,
            options: ["funny & playful", "loyal & dependable", "adventurous & driven", "chill & easygoing", "thoughtful & empathetic", "outgoing & social", "deep & intellectual", "creative & artistic", "open-minded", "honest & authentic"],
            canBeMustHave: true,
            maxSelection: 4
        ),
        SurveyQuestion(
            id: .idealConnection,
            question: "my ideal connection involves:",
            type: .multiSelect,
            options: ["deep conversations & emotional support", "fun & lighthearted energy", "shared activities & hobbies", "going out together", "intellectual discussions", "adventure & trying new things", "low-key, chill vibes", "ambitious / growth-minded conversations"],
            canBeMustHave: false,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .industry,
            question: "what industry are you in?",
            type: .singleSelect,
            options: ["tech / startups", "finance / consulting", "creative / media / entertainment", "healthcare / medicine", "education / academia", "legal", "sales / marketing", "service / hospitality", "trades", "student", "between jobs / exploring", "other"],
            canBeMustHave: false,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .relationshipStatus,
            question: "relationship status:",
            type: .singleSelect,
            options: ["single", "casually dating", "in a relationship", "it's complicated"],
            canBeMustHave: true,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .sexualOrientation,
            question: "sexual orientation:",
            type: .singleSelect,
            options: ["straight", "gay / lesbian", "bisexual", "pansexual", "questioning", "prefer not to say"],
            canBeMustHave: false,
            maxSelection: nil
        ),
        SurveyQuestion(
            id: .musicGenres,
            question: "music genres you enjoy:",
            type: .multiSelect,
            options: ["hip-hop / rap", "edm / house / techno", "pop / top 40", "r&b / soul", "rock / alternative / indie", "latin / reggaeton", "country", "jazz / blues", "classical", "i'm open to everything"],
            canBeMustHave: false,
            maxSelection: 5
        ),
        SurveyQuestion(
            id: .drinkingHabits,
            question: "drinking habits:",
            type: .singleSelect,
            options: ["i drink regularly and enjoy going out", "social drinker — occasional nights out", "drink rarely", "don't drink", "sober lifestyle"],
            canBeMustHave: true,
            maxSelection: nil
        )
    ]
    
    // MARK: - Load existing survey
    func load() {
        isLoading = true
        
        NetworkManager.shared.get(
            endpoint: "/survey",
            parameters: nil
        ) { [weak self] (result: Result<SurveyAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    for responseData in data.responses {
                        guard let questionId = SurveyQuestionID(rawValue: responseData.questionId) else {
                            continue
                        }
                        
                        // Handle both String and Array values from AnyCodable
                        let value: Any
                        if let stringValue = responseData.value.value as? String {
                            value = stringValue
                        } else if let arrayValue = responseData.value.value as? [String] {
                            value = arrayValue
                        } else {
                            continue
                        }
                        
                        self?.responses[questionId] = (value: value, isMustHave: responseData.isMustHave)
                    }
                    
                    // Check if all questions are answered
                    self?.isComplete = self?.responses.count == self?.questions.count
                case .failure(let error):
                    Log.error("failed to load survey: \(error)")
                    self?.errorMessage = "failed to load survey"
                }
            }
        }
    }
    
    // MARK: - Submit survey
    func submit(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Convert responses to API format
        var apiResponses: [[String: Any]] = []
        
        for (questionId, response) in responses {
            var responseDict: [String: Any] = [
                "questionId": questionId.rawValue,
                "isMustHave": response.isMustHave
            ]
            
            // Encode value based on type
            if let stringValue = response.value as? String {
                responseDict["value"] = stringValue
            } else if let arrayValue = response.value as? [String] {
                responseDict["value"] = arrayValue
            }
            
            apiResponses.append(responseDict)
        }
        
        let body: [String: Any] = ["responses": apiResponses]
        
        NetworkManager.shared.post(
            endpoint: "/survey/submit",
            parameters: body
        ) { [weak self] (result: Result<SurveyAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.isComplete = true
                    Log.debug("survey submitted successfully")
                    completion(true)
                case .failure(let error):
                    Log.error("failed to submit survey: \(error)")
                    self?.errorMessage = "failed to submit survey"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Helper methods
    func setResponse(for questionId: SurveyQuestionID, value: Any, isMustHave: Bool) {
        responses[questionId] = (value: value, isMustHave: isMustHave)
    }
    
    func getResponse(for questionId: SurveyQuestionID) -> (value: Any, isMustHave: Bool)? {
        return responses[questionId]
    }
    
    func toggleMustHave(for questionId: SurveyQuestionID) {
        if let existing = responses[questionId] {
            responses[questionId] = (value: existing.value, isMustHave: !existing.isMustHave)
        }
    }
    
    func isQuestionAnswered(_ questionId: SurveyQuestionID) -> Bool {
        guard let response = responses[questionId] else { return false }
        
        if let stringValue = response.value as? String, !stringValue.isEmpty {
            return true
        } else if let arrayValue = response.value as? [String], !arrayValue.isEmpty {
            return true
        }
        
        return false
    }
}

