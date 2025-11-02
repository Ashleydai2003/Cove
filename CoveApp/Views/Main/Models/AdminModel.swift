import Foundation

/// Model for managing admin-related data and operations
@MainActor
class AdminModel: ObservableObject {
    @Published var users: [AdminUser] = []
    @Published var matches: [AdminMatch] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreUsers: Bool = true
    @Published var hasMoreMatches: Bool = true
    
    private var currentUserPage = 0
    private var currentMatchPage = 0
    private let pageSize = 20
    
    /// Fetch users with pagination (superadmin only)
    func fetchUsers(refresh: Bool = false) {
        // If refreshing, reset pagination
        if refresh {
            currentUserPage = 0
            users = []
            hasMoreUsers = true
        }
        
        // Don't fetch if already loading or no more data
        guard !isLoading && hasMoreUsers else { return }
        
        isLoading = true
        errorMessage = nil
        
        let parameters: [String: Any] = [
            "page": currentUserPage,
            "limit": pageSize
        ]
        
        NetworkManager.shared.get(
            endpoint: "/admin/users",
            parameters: parameters
        ) { (result: Result<AdminUsersResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if refresh {
                        self.users = response.users
                    } else {
                        self.users.append(contentsOf: response.users)
                    }
                    
                    // Check if there are more users to load
                    self.hasMoreUsers = response.users.count == self.pageSize
                    self.currentUserPage += 1
                    
                    print("✅ Fetched \(response.users.count) users (page \(self.currentUserPage), total: \(self.users.count))")
                case .failure(let error):
                    self.errorMessage = "Failed to load users: \(error.localizedDescription)"
                    print("❌ Failed to fetch users: \(error)")
                }
            }
        }
    }
    
    /// Toggle superadmin status for a user (superadmin only)
    func toggleSuperadmin(for user: AdminUser) {
        let newStatus = !user.superadmin
        
        let parameters: [String: Any] = [
            "targetUserId": user.id,
            "superadmin": newStatus
        ]
        
        NetworkManager.shared.post(
            endpoint: "/admin/toggle-superadmin",
            parameters: parameters
        ) { (result: Result<ToggleSuperadminResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Update local user list
                    if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                        self.users[index].superadmin = newStatus
                    }
                    print("✅ Toggled superadmin status for user \(user.id)")
                case .failure(let error):
                    self.errorMessage = "Failed to toggle superadmin: \(error.localizedDescription)"
                    print("❌ Failed to toggle superadmin: \(error)")
                }
            }
        }
    }
    
    /// Fetch matches with pagination (superadmin only)
    func fetchMatches(refresh: Bool = false) {
        // If refreshing, reset pagination
        if refresh {
            currentMatchPage = 0
            matches = []
            hasMoreMatches = true
        }
        
        // Don't fetch if already loading or no more data
        guard !isLoading && hasMoreMatches else { return }
        
        isLoading = true
        errorMessage = nil
        
        let parameters: [String: Any] = [
            "page": currentMatchPage,
            "limit": pageSize
        ]
        
        NetworkManager.shared.get(
            endpoint: "/admin/matches",
            parameters: parameters
        ) { (result: Result<AdminMatchesResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if refresh {
                        self.matches = response.matches
                    } else {
                        self.matches.append(contentsOf: response.matches)
                    }
                    
                    // Check if there are more matches to load
                    self.hasMoreMatches = response.matches.count == self.pageSize
                    self.currentMatchPage += 1
                    
                    print("✅ Fetched \(response.matches.count) matches (page \(self.currentMatchPage), total: \(self.matches.count))")
                case .failure(let error):
                    self.errorMessage = "Failed to load matches: \(error.localizedDescription)"
                    print("❌ Failed to fetch matches: \(error)")
                }
            }
        }
    }
    
    /// Fetch user matching details (superadmin only)
    func fetchUserDetails(userId: String, completion: @escaping (Result<AdminUserDetails, NetworkError>) -> Void) {
        NetworkManager.shared.get(
            endpoint: "/admin/user-details",
            parameters: ["userId": userId]
        ) { (result: Result<AdminUserDetails, NetworkError>) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Match Management Operations
    
    /// Create a manual match with selected users (superadmin only)
    func createMatch(userIds: [String], tierUsed: Int = 0, score: Double = 0.8, completion: @escaping (Result<AdminMatch, NetworkError>) -> Void) {
        let parameters: [String: Any] = [
            "userIds": userIds,
            "tierUsed": tierUsed,
            "score": score
        ]
        
        NetworkManager.shared.post(
            endpoint: "/admin/matches/create",
            parameters: parameters
        ) { (result: Result<CreateMatchResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Refresh matches list
                    self.fetchMatches(refresh: true)
                    completion(.success(response.match))
                case .failure(let error):
                    self.errorMessage = "Failed to create match: \(error.localizedDescription)"
                    print("❌ Failed to create match: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Add a user to an existing match (superadmin only)
    func addUserToMatch(matchId: String, userId: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        let parameters: [String: Any] = [
            "userId": userId
        ]
        
        NetworkManager.shared.post(
            endpoint: "/admin/matches/\(matchId)/add-member",
            parameters: parameters
        ) { (result: Result<SimpleMessageResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Refresh matches list
                    self.fetchMatches(refresh: true)
                    completion(.success(response.message))
                case .failure(let error):
                    self.errorMessage = "Failed to add user to match: \(error.localizedDescription)"
                    print("❌ Failed to add user to match: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Remove a user from a match (superadmin only)
    func removeUserFromMatch(matchId: String, userId: String, returnToPool: Bool = false, completion: @escaping (Result<String, NetworkError>) -> Void) {
        let parameters: [String: Any] = [
            "userId": userId,
            "returnToPool": returnToPool
        ]
        
        NetworkManager.shared.post(
            endpoint: "/admin/matches/\(matchId)/remove-member",
            parameters: parameters
        ) { (result: Result<SimpleMessageResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Refresh matches list
                    self.fetchMatches(refresh: true)
                    completion(.success(response.message))
                case .failure(let error):
                    self.errorMessage = "Failed to remove user from match: \(error.localizedDescription)"
                    print("❌ Failed to remove user from match: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Move a user from one match to another (superadmin only)
    func moveUserBetweenMatches(userId: String, fromMatchId: String, toMatchId: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        let parameters: [String: Any] = [
            "userId": userId,
            "toMatchId": toMatchId
        ]
        
        NetworkManager.shared.post(
            endpoint: "/admin/matches/\(fromMatchId)/move-member",
            parameters: parameters
        ) { (result: Result<SimpleMessageResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Refresh matches list
                    self.fetchMatches(refresh: true)
                    completion(.success(response.message))
                case .failure(let error):
                    self.errorMessage = "Failed to move user between matches: \(error.localizedDescription)"
                    print("❌ Failed to move user between matches: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Delete a match (superadmin only)
    func deleteMatch(matchId: String, returnToPool: Bool = false, completion: @escaping (Result<String, NetworkError>) -> Void) {
        var endpoint = "/admin/matches/\(matchId)"
        if returnToPool {
            endpoint += "?returnToPool=true"
        }
        
        NetworkManager.shared.delete(
            endpoint: endpoint,
            parameters: [:]
        ) { (result: Result<SimpleMessageResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Remove match from local list
                    self.matches.removeAll { $0.id == matchId }
                    completion(.success(response.message))
                case .failure(let error):
                    self.errorMessage = "Failed to delete match: \(error.localizedDescription)"
                    print("❌ Failed to delete match: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Models

struct AdminUser: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String
    let onboarding: Bool
    let verified: Bool
    var superadmin: Bool
    let createdAt: String
    let age: Int?
    let city: String?
    let almaMater: String?
    
    var displayName: String {
        name == "N/A" ? "Unknown" : name
    }
    
    var formattedCreatedAt: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

struct AdminUsersResponse: Codable {
    let users: [AdminUser]
    let count: Int
}

struct ToggleSuperadminResponse: Codable {
    let message: String
    let targetUserId: String
    let superadmin: Bool
}

// MARK: - Match Models

struct AdminMatch: Codable, Identifiable {
    let id: String
    let groupSize: Int
    let status: String
    let score: Double?
    let tierUsed: Int?
    let createdAt: String
    let members: [AdminMatchMember]
    
    var formattedCreatedAt: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var formattedScore: String {
        guard let score = score else { return "N/A" }
        let percentage = Int(score * 100)
        return "\(percentage)%"
    }
}

struct AdminMatchMember: Codable, Identifiable {
    let userId: String
    let name: String
    let phone: String
    let age: Int?
    let city: String?
    let almaMater: String?
    
    var id: String { userId }
    
    var displayName: String {
        name == "N/A" ? "Unknown" : name
    }
}

struct AdminMatchesResponse: Codable {
    let matches: [AdminMatch]
    let count: Int
}

// MARK: - Unmatched Users Response

struct UnmatchedUserInfo: Codable {
    let user: AdminUserInfo
    let activeIntention: AdminIntention?
}

struct UnmatchedUsersResponse: Codable {
    let users: [UnmatchedUserInfo]
    let count: Int
}

// MARK: - User Details Models

struct AdminUserDetails: Codable {
    let user: AdminUserInfo
    let survey: [AdminSurveyResponse]
    let activeIntention: AdminIntention?
    let pastIntentions: [AdminIntention]
}

struct AdminUserInfo: Codable {
    let id: String
    let name: String
    let phone: String
    let age: Int?
    let city: String?
    let almaMater: String?
}

struct AdminSurveyResponse: Codable {
    let questionId: String
    let value: AnyCodable
    let answeredAt: String
}

struct AdminIntention: Codable, Identifiable {
    let id: String
    let text: String
    let parsedJson: AnyCodable?
    let status: String
    let createdAt: String
    let validUntil: String
    let poolEntry: AdminPoolEntry?
    
    var formattedCreatedAt: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

struct AdminPoolEntry: Codable {
    let tier: Int
    let joinedAt: String
}

// MARK: - API Response Models

struct SimpleMessageResponse: Codable {
    let message: String
}

struct CreateMatchResponse: Codable {
    let message: String
    let match: AdminMatch
}
