import Foundation
import Combine

@MainActor
class InvitesViewModel: ObservableObject {
    @Published var invites: [InviteModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedInvite: InviteModel?
    
    /// Fetches pending invites for the current user
    func fetchInvites() {
        isLoading = true
        errorMessage = nil
        
        print("📮 Fetching pending invites...")
        
        NetworkManager.shared.get(
            endpoint: "/invites",
            parameters: nil
        ) { [weak self] (result: Result<InvitesResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Invites fetched successfully: \(response.invites.count) invites")
                    self.invites = response.invites
                case .failure(let error):
                    print("❌ Failed to fetch invites: \(error)")
                    self.errorMessage = "Failed to load invites: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Opens an invite for user to accept/decline
    func openInvite(_ invite: InviteModel) {
        selectedInvite = invite
    }
    
    /// Accepts an invite and joins the cove
    func acceptInvite(_ invite: InviteModel) {
        print("✅ Accepting invite to \(invite.cove.name)")
        
        // TODO: Implement accept invite API call
        // For now, just remove from list
        removeInvite(invite)
        selectedInvite = nil
    }
    
    /// Declines an invite
    func declineInvite(_ invite: InviteModel) {
        print("❌ Declining invite to \(invite.cove.name)")
        
        // TODO: Implement decline invite API call
        // For now, just remove from list
        removeInvite(invite)
        selectedInvite = nil
    }
    
    /// Removes an invite from the list
    private func removeInvite(_ invite: InviteModel) {
        invites.removeAll { $0.id == invite.id }
    }
}

// MARK: - Response Models

/// Response from /invites API
struct InvitesResponse: Decodable {
    let invites: [InviteModel]
}

/// Individual invite model
struct InviteModel: Decodable, Identifiable {
    let id: String
    let phoneNumber: String
    let message: String?
    let isOpened: Bool
    let createdAt: String
    let cove: InviteCove
    let sender: InviteSender
    
    struct InviteCove: Decodable {
        let id: String
        let name: String
        let description: String?
        let location: String
    }
    
    struct InviteSender: Decodable {
        let id: String
        let name: String?
    }
} 