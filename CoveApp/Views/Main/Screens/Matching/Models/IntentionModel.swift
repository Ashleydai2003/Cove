//
//  IntentionModel.swift
//  Cove
//
//  AI Matching System - Intention Model
//

import Foundation

// MARK: - Intention Data Structures
struct IntentionChips: Codable {
    var who: WhoChips
    var what: WhatChips
    var when: [String]
    var location: String
    var vibe: [String]
    var mustHaves: [String]
    var dealbreakers: [String]
    
    struct WhoChips: Codable {
        var network: String?
        var ageBand: String?
        var genderPref: String
        
        enum CodingKeys: String, CodingKey {
            case network, ageBand, genderPref
        }
    }
    
    struct WhatChips: Codable {
        var activities: [String]
        var notes: String
    }
}

struct Intention: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let validUntil: String
    let status: String
}

struct PoolEntry: Codable {
    let tier: Int
    let nextBatchEta: String
    let joinedAt: String?
}

struct IntentionStatus: Codable {
    let hasIntention: Bool
    let intention: Intention?
    let poolEntry: PoolEntry?
    let hasMatch: Bool
}

// MARK: - Intention Model
@MainActor
class IntentionModel: ObservableObject {
    @Published var currentIntention: Intention?
    @Published var poolEntry: PoolEntry?
    @Published var hasMatch: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Intention composer state
    @Published var selectedActivities: [String] = []
    @Published var selectedTimeWindows: [String] = []
    @Published var selectedVibe: [String] = []
    @Published var notesText: String = ""
    @Published var userCity: String = "palo alto" // Will load from profile
    
    // Available options
    let activityOptions = ["coffee", "live music", "art walk", "dinner", "outdoors"]
    let timeWindowOptions = ["fri evening", "sat daytime", "sat evening", "sun daytime"]
    let vibeOptions = ["low-key", "outgoing", "intellectual", "adventurous"]
    
    var currentTier: Int {
        return poolEntry?.tier ?? 0
    }
    
    var nextBatchEta: Date? {
        guard let poolEntry = poolEntry else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: poolEntry.nextBatchEta)
    }
    
    // MARK: - Load intention status
    func load() {
        isLoading = true
        
        NetworkManager.shared.get(
            endpoint: "/intention/status",
            parameters: nil
        ) { [weak self] (result: Result<IntentionAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    if data.hasIntention == true {
                        // Parse intention
                        if let intentionData = data.intention {
                            self?.currentIntention = Intention(
                                id: intentionData.id,
                                text: intentionData.text,
                                validUntil: intentionData.validUntil,
                                status: intentionData.status
                            )
                        }
                        
                        // Parse pool entry
                        if let poolData = data.poolEntry {
                            self?.poolEntry = PoolEntry(
                                tier: poolData.tier,
                                nextBatchEta: poolData.nextBatchEta,
                                joinedAt: poolData.joinedAt
                            )
                        }
                        
                        // Check if has match
                        self?.hasMatch = data.hasMatch ?? false
                    }
                    
                    // Load user city from profile
                    self?.loadUserCity()
                    
                case .failure(let error):
                    Log.error("failed to load intention status: \(error)")
                    self?.errorMessage = "failed to load status"
                }
            }
        }
    }
    
    // MARK: - Load user city from profile
    private func loadUserCity() {
        NetworkManager.shared.get(
            endpoint: "/profile",
            parameters: nil
        ) { [weak self] (result: Result<ProfileAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileData):
                    if let city = profileData.profile.city {
                        self?.userCity = city
                    }
                case .failure(let error):
                    Log.error("failed to load user city: \(error)")
                }
            }
        }
    }
    
    // MARK: - Submit intention
    func submitIntention(activities: [String], timeWindows: [String], vibe: [String], notes: String, completion: @escaping (Bool) -> Void) {
        print("📤 [IntentionModel] submitIntention called")
        print("   - Activities: \(activities)")
        print("   - Time windows: \(timeWindows)")
        print("   - Notes: \(notes)")
        print("   - User city: \(userCity)")
        
        isLoading = true
        
        // Build chips structure
        let chips = IntentionChips(
            who: IntentionChips.WhoChips(
                network: nil,
                ageBand: nil,
                genderPref: "any"
            ),
            what: IntentionChips.WhatChips(
                activities: activities,
                notes: notes
            ),
            when: timeWindows,
            location: userCity,
            vibe: vibe,
            mustHaves: ["location", "when"],
            dealbreakers: []
        )
        
        // Generate text from chips
        let text = generateText(from: chips)
        print("📝 [IntentionModel] Generated text: \(text)")
        
        let body: [String: Any] = [
            "text": text,
            "chips": (try? chips.toDictionary()) ?? [:]
        ]
        
        print("🌐 [IntentionModel] Sending POST /intention request...")
        
        NetworkManager.shared.post(
            endpoint: "/intention",
            parameters: body
        ) { [weak self] (result: Result<IntentionAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    print("✅ [IntentionModel] POST /intention success!")
                    print("   - Response intention: \(data.intention?.id ?? "nil")")
                    print("   - Response poolEntry: \(data.poolEntry != nil ? "present" : "nil")")
                    
                    // Parse response
                    if let intentionData = data.intention {
                        let newIntention = Intention(
                            id: intentionData.id,
                            text: text,
                            validUntil: intentionData.validUntil,
                            status: intentionData.status
                        )
                        print("💾 [IntentionModel] Setting currentIntention to: \(newIntention.id)")
                        self?.currentIntention = newIntention
                        print("✨ [IntentionModel] currentIntention is now: \(self?.currentIntention?.id ?? "still nil!")")
                    } else {
                        print("⚠️ [IntentionModel] No intention data in response!")
                    }
                    
                    if let poolData = data.poolEntry {
                        self?.poolEntry = PoolEntry(
                            tier: poolData.tier,
                            nextBatchEta: poolData.nextBatchEta,
                            joinedAt: poolData.joinedAt
                        )
                        print("💾 [IntentionModel] Set poolEntry tier: \(poolData.tier)")
                    }
                    
                    completion(true)
                case .failure(let error):
                    print("❌ [IntentionModel] POST /intention failed: \(error)")
                    self?.errorMessage = "failed to submit intention"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete intention
    func deleteIntention(completion: @escaping (Bool) -> Void) {
        guard let intention = currentIntention else { 
            completion(false)
            return 
        }
        
        isLoading = true
        
        NetworkManager.shared.delete(
            endpoint: "/intention/\(intention.id)",
            parameters: [:]
        ) { [weak self] (result: Result<IntentionAPIResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.currentIntention = nil
                    self?.poolEntry = nil
                    self?.hasMatch = false
                    
                    // Reset form
                    self?.selectedActivities = []
                    self?.selectedTimeWindows = []
                    self?.selectedVibe = []
                    self?.notesText = ""
                    
                    Log.debug("intention deleted successfully")
                    completion(true)
                case .failure(let error):
                    Log.error("failed to delete intention: \(error)")
                    self?.errorMessage = "failed to delete intention"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Refresh status
    func refresh() {
        load()
    }
    
    // MARK: - Edit intention
    func editIntention() {
        // Delete current intention to allow editing
        deleteIntention { _ in }
    }
    
    // MARK: - Helper: Generate text from chips
    private func generateText(from chips: IntentionChips) -> String {
        var parts: [String] = []
        
        if !chips.what.activities.isEmpty {
            parts.append(chips.what.activities.joined(separator: " or "))
        }
        
        if !chips.when.isEmpty {
            parts.append(chips.when.joined(separator: " or "))
        }
        
        parts.append("in \(chips.location)")
        
        if !chips.what.notes.isEmpty {
            parts.append("(\(chips.what.notes))")
        }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Codable Extension for IntentionChips
extension IntentionChips {
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        return json as? [String: Any] ?? [:]
    }
}

