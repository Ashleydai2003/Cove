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
    private static var userGradYear: String?
    private static var userCity: String?
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

    static func storeGradYear(gradYear: String) -> Void {
        userGradYear = gradYear
    }

    static func storeCity(city: String) -> Void {
        userCity = city
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
            case .success(_):
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
    
    // MARK: - Debug Methods
    /// Clears all onboarding data (for debugging)
    static func clearAllData() {
        userName = nil
        userBirthdate = nil
        userHobbies = []
        userAlmaMater = nil
        userGradYear = nil
        userCity = nil
        profilePic = nil
        pendingFriendRequests = []
        adminCove = nil
        Log.debug("Onboarding data cleared")
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

    static func getGradYear() -> String? {
        return userGradYear
    }

    static func getCity() -> String? {
        return userCity
    }

    // MARK: - Validation
    // Updated to reflect new backend requirements
    static func isOnboardingComplete() -> Bool {
        // Core required fields: name, birthdate, university, city
        // Optional fields: profilePic, hobbies (archived)
        
        let hasName = userName != nil && !userName!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBirthdate = userBirthdate != nil
        let hasAlmaMater = userAlmaMater != nil && !userAlmaMater!.isEmpty
        
        // Log what's missing for debugging
        if !hasName {
            Log.error("Onboarding incomplete: Missing name")
        }
        if !hasBirthdate {
            Log.error("Onboarding incomplete: Missing birthdate")
        }
        if !hasAlmaMater {
            Log.error("Onboarding incomplete: Missing almaMater")
        }
        
        return hasName && hasBirthdate && hasAlmaMater
    }

    /// Completes the onboarding process by updating the user's onboarding status
    /// - Parameter completion: Callback with success status
    static func completeOnboarding(completion: @escaping (Bool) -> Void) {
        // Check if onboarding is complete with necessary data
        if isOnboardingComplete() {
            // Step 1: Upload profile picture if it exists
            if let profileImage = profilePic {
                uploadProfilePicture(profileImage) { uploadSuccess in
                    if uploadSuccess {
                        // Step 2: Send friend requests
                        sendPendingFriendRequests { friendRequestSuccess in
                            if friendRequestSuccess {
                                // Step 3: Update onboarding status
                                makeOnboardingCompleteRequest { onboardingSuccess in
                                    if onboardingSuccess {
                                        // Clear data after successful completion
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
                    } else {
                        completion(false)
                    }
                }
            } else {
                // No profile picture to upload, proceed with friend requests
                sendPendingFriendRequests { friendRequestSuccess in
                    if friendRequestSuccess {
                        // Update onboarding status
                        makeOnboardingCompleteRequest { onboardingSuccess in
                            if onboardingSuccess {
                                // Clear data after successful completion
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
        } else {
            Log.error("Onboarding incomplete, missing required fields")
            Task { @MainActor in
                AppController.shared.errorMessage = "Please complete all required fields before continuing"
                // Don't navigate anywhere - stay on current screen to show error
                // Or navigate back to collect missing data
                // AppController.shared.path = [.userDetails] // Could navigate back to details if needed
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

    // MARK: - Private Helper Methods

    /// Uploads the profile picture to the backend
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - completion: Callback with success status
    private static func uploadProfilePicture(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            Log.error("Failed to convert profile picture to JPEG data")
            completion(false)
            return
        }

        // Upload using UserImage utility
        UserImage.upload(imageData: imageData, isProfilePic: true) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    Log.debug("Profile picture uploaded successfully")
                    completion(true)
                case .failure(let error):
                    Log.error("Profile picture upload failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }

    private static func makeOnboardingCompleteRequest(completion: @escaping (Bool) -> Void) {
        // Validate required fields before making the request
        guard let name = userName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let birthdate = userBirthdate,
              let almaMater = userAlmaMater, !almaMater.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let gradYear = userGradYear, !gradYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Log.error("Missing required fields for onboarding")
            completion(false)
            return
        }

        // Format date to ISO 8601
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let formattedDate = dateFormatter.string(from: birthdate)

        // Create request parameters with mandatory fields first
        var parameters: [String: Any] = [
            "name": userName ?? "",
            "birthdate": formattedDate
            // Note: hobbies removed from onboarding flow
        ]

        // Add required fields
        if let almaMater = userAlmaMater, !almaMater.isEmpty {
            parameters["almaMater"] = almaMater
        }
        
        if let graduationYear = userGradYear, !graduationYear.isEmpty {
            parameters["graduationYear"] = graduationYear
        }

        // Add optional fields
        if !userHobbies.isEmpty {
            parameters["hobbies"] = Array(userHobbies)
        }

        if let city = userCity, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parameters["city"] = city.trimmingCharacters(in: .whitespacesAndNewlines)
        }

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
