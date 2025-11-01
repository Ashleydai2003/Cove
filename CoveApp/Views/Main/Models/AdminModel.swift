import Foundation

/// Model for managing admin-related data and operations
@MainActor
class AdminModel: ObservableObject {
    @Published var users: [AdminUser] = []
    @Published var matches: [AdminMatch] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Fetch all users (superadmin only)
    func fetchUsers() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.get(
            endpoint: "/admin/users"
        ) { (result: Result<AdminUsersResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.users = response.users
                    print("✅ Fetched \(response.count) users")
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
    
    /// Fetch all matches (superadmin only)
    func fetchMatches() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.get(
            endpoint: "/admin/matches"
        ) { (result: Result<AdminMatchesResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.matches = response.matches
                    print("✅ Fetched \(response.count) matches")
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
