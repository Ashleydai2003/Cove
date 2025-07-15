//
//  Onboarding.swift
//  Cove
//
//  Created by Ashley Dai on 5/13/25.
//

import Foundation
import SwiftUI

class Onboarding {
    // MARK: - Properties
    private static var userName: String?
    private static var userBirthdate: Date?
    private static var userHobbies: Set<String> = []
    private static var userAlmaMater: String?
    private static var profilePic: UIImage?
    private static var pendingFriendRequests: [String] = []
    private static var adminCove: String?
    
    private static let apiBaseURL = AppConstants.API.baseURL
    private static let apiOnboardPath = "/onboard"
    
    // MARK: - Public Methods
    static func storeName(firstName: String, lastName: String) -> Void {
        userName = firstName + " " + lastName
    }
    
    static func storeBirthdate(birthDate: Date) -> Void {
        userBirthdate = birthDate
    }

    static func storeHobbies(hobbies: Set<String>) -> Void {
        userHobbies = hobbies
    }

    static func storeAlmaMater(almaMater: String) -> Void {
        userAlmaMater = almaMater
    }

    // MARK: - Admin Functions
    static func setAdminCove(adminCove: String) -> Void {
        self.adminCove = adminCove
    }

    static func getAdminCove() -> String? {
        return adminCove
    }
    
    // MARK: - Friend Requests 
    static func addFriendRequest(userId: String) {
        pendingFriendRequests.append(userId)
    }
    
    static func removeFriendRequest(userId: String) {
        pendingFriendRequests.removeAll { $0 == userId }
    }
    
    static func clearPendingFriendRequests() {
        pendingFriendRequests.removeAll()
    }
    
    static func sendPendingFriendRequests(completion: @escaping (Bool) -> Void) {
        guard !pendingFriendRequests.isEmpty else {
            completion(true)
            return
        }
        
        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: ["toUserIds": pendingFriendRequests]
        ) { (result: Result<FriendRequestResponse, NetworkError>) in
            switch result {
            case .success(let response):
                pendingFriendRequests.removeAll()
                completion(true)
                
            case .failure(let error):
                Log.error("Failed to send friend requests: \(error.localizedDescription)")
                completion(false)
            }
        }
    } 

    // MARK: - Image Storage
    static func storeProfilePic(_ image: UIImage) {
        profilePic = image
    }
    
    static func clearImages() {
        profilePic = nil
    }
    
    static func getAllImages() -> [(UIImage, Bool)] {
        var images: [(UIImage, Bool)] = []
        if let profile = profilePic {
            images.append((profile, true))
        }
        return images
    }
    
    // MARK: - Getters
    static func getName() -> String? {
        return userName
    }
    
    static func getBirthdate() -> Date? {
        return userBirthdate
    }
    
    static func getHobbies() -> Set<String> {
        return userHobbies
    }

    static func getAlmaMater() -> String? {
        return userAlmaMater
    }

    static func getJob() -> String? {
        return userJob
    }

    static func getWorkLocation() -> String? {
        return userWorkLocation
    }

    static func getRelationStatus() -> String? {
        return userRelationStatus
    }

    static func getInterestedInto() -> String? {
        return userInterestedInto
    }
    
    // MARK: - Validation
    static func isOnboardingComplete() -> Bool {
        return userName != nil && userBirthdate != nil && !userHobbies.isEmpty
    }

    /// Completes the onboarding process by updating the user's onboarding status
    /// - Parameter completion: Callback with success status
    static func completeOnboarding(completion: @escaping (Bool) -> Void) {
        // Send friend requests first
        sendPendingFriendRequests { friendRequestSuccess in
            if friendRequestSuccess {
                // Update onboarding status
                makeOnboardingCompleteRequest { onboardingSuccess in
                    if onboardingSuccess {
                        // Clear pending friend requests after successful completion
                        clearPendingFriendRequests()
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        } else {
            print("❌ Onboarding incomplete, missing required fields")
            Task { @MainActor in
            AppController.shared.errorMessage = "Onboarding process incomplete"
            AppController.shared.path = [.pluggingIn]
            }
            completion(false)
        }
    }

    // MARK: - Response Models
    struct OnboardResponse: Decodable {
        let message: String
    }
    
    struct FriendRequestResponse: Decodable {
        let message: String
        let requestIds: [String]?
    }

    private static func makeOnboardingCompleteRequest(completion: @escaping (Bool) -> Void) {
        // Format date to ISO 8601
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = userBirthdate.map { dateFormatter.string(from: $0) } ?? ""
        
        // Create request parameters with only the data we actually collect
        let parameters: [String: Any] = [
            "name": userName ?? "",
            "birthdate": formattedDate,
            "hobbies": Array(userHobbies),  // Convert Set to Array for JSON serialization
            "almaMater": userAlmaMater ?? ""
        ]
        
        NetworkManager.shared.post(
            endpoint: "/onboard",
            parameters: parameters
        ) { (result: Result<OnboardResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completion(true)
                case .failure(let error):
                    Log.error("Onboarding completion failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
}
