import SwiftUI
import Foundation

// MARK: - Friend Profile DTOs
struct FriendProfilePhoto: Decodable {
    let id: String
    let url: URL
    let isProfilePic: Bool
}

struct FriendProfileStats: Decodable {
    let sharedCoveCount: Int?
    let sharedEventCount: Int?
    let sharedFriendCount: Int?
}

struct FriendProfileData: Decodable {
    let name: String
    let userId: String
    let id: String
    let bio: String?
    let interests: [String]
    let latitude: Double?
    let longitude: Double?
    let photos: [FriendProfilePhoto]
    let stats: FriendProfileStats?
}

struct FriendProfileResponse: Decodable {
    let profile: FriendProfileData
}

/// FriendProfileModel: Fetches and stores another user's profile details for FriendProfileView
@MainActor
class FriendProfileModel: ObservableObject {
    @Published var profileData: FriendProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName: String = "" // Human-readable location derived from coordinates

    func fetchProfile(userId: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.get(endpoint: "/profile", parameters: ["userId": userId]) { [weak self] (result: Result<FriendProfileResponse, NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let resp):
                self.profileData = resp.profile
                // Fetch human-readable location
                if let lat = resp.profile.latitude, let lon = resp.profile.longitude {
                    Task {
                        let loc = await LocationUtils.getLocationName(latitude: lat, longitude: lon)
                        await MainActor.run {
                            self.locationName = loc
                        }
                    }
                } else {
                    self.locationName = ""
                }
            case .failure(let err):
                self.errorMessage = err.localizedDescription
            }
        }
    }

    var actionState: ActionState {
        // Determine friendship state from AppController shared view models
        guard let profile = profileData else { return .loading }
        let currentId = AppController.shared.profileModel.userId
        if currentId == profile.userId { return .none }

        let friendsVM = AppController.shared.friendsViewModel
        if friendsVM.friends.contains(where: { $0.id == profile.userId }) {
            return .message
        }
        let requestsVM = AppController.shared.requestsViewModel
        if let req = requestsVM.requests.first(where: { $0.sender.id == profile.userId }) {
            return .incomingRequest(req)
        }
        let mutualsVM = AppController.shared.mutualsViewModel
        if mutualsVM.pendingRequests.contains(profile.userId) {
            return .pending
        }
        return .sendRequest
    }

    enum ActionState {
        case loading
        case none // viewing self
        case message
        case incomingRequest(RequestDTO)
        case pending
        case sendRequest
    }
} 