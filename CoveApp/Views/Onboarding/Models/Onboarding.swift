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
    private static var userBio: String?
    private static var userLatitude: Double?
    private static var userLongitude: Double?
    private static var userAlmaMater: String?
    private static var userJob: String?
    private static var userWorkLocation: String?
    private static var userRelationStatus: String?
    private static var userInterestedInto: String?
    private static var userGender: String?
    private static var profilePic: UIImage?
    private static var extraPics: [UIImage] = []
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

    static func storeBio(bio: String) -> Void {
        userBio = bio
    }

    static func storeLocation(latitude: Double, longitude: Double) -> Void {
        userLatitude = latitude
        userLongitude = longitude
    }

    static func storeAlmaMater(almaMater: String) -> Void {
        userAlmaMater = almaMater
    }

    static func storeMoreAboutYou(job: String, workLocation: String, relationStatus: String, interestedInto: String, gender: String) -> Void {
        userJob = job
        userWorkLocation = workLocation
        userRelationStatus = relationStatus
        userInterestedInto = interestedInto
        userGender = gender
    }

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
    
    static func storeExtraPic(_ image: UIImage, at index: Int) {
        if index >= extraPics.count {
            extraPics.append(image)
        } else {
            extraPics[index] = image
        }
        // Ensure we only keep 2 extra pics
        if extraPics.count > 2 {
            extraPics = Array(extraPics.prefix(2))
        }
    }
    
    static func clearImages() {
        profilePic = nil
        extraPics.removeAll()
    }
    
    static func getAllImages() -> [(UIImage, Bool)] {
        var images: [(UIImage, Bool)] = []
        if let profile = profilePic {
            images.append((profile, true))
        }
        images.append(contentsOf: extraPics.map { ($0, false) })
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

    static func getBio() -> String? {
        return userBio
    }

    static func getLocation() -> (Double?, Double?) {
        return (userLatitude, userLongitude)
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
        return userName != nil && userBirthdate != nil && !userHobbies.isEmpty && userBio != nil && userLatitude != nil && userLongitude != nil
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
        
        // Create request parameters
        let parameters: [String: Any] = [
            "name": userName ?? "",
            "birthdate": formattedDate,
            "hobbies": Array(userHobbies),  // Convert Set to Array for JSON serialization
            "bio": userBio ?? "",
            "latitude": userLatitude ?? 0,
            "longitude": userLongitude ?? 0,
            "almaMater": userAlmaMater ?? "",
            "job": userJob ?? "",
            "workLocation": userWorkLocation ?? "",
            "relationStatus": userRelationStatus ?? "",
            "sexuality": userInterestedInto ?? "",
            "gender": userGender ?? ""
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
