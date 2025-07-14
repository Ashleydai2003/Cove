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
        
        print("📱 Sending friend requests to: \(pendingFriendRequests)")
        
        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: ["toUserIds": pendingFriendRequests]
        ) { (result: Result<FriendRequestResponse, NetworkError>) in
            switch result {
            case .success(let response):
                print("✅ Friend requests sent successfully: \(response.message)")
                pendingFriendRequests.removeAll()
                completion(true)
                
            case .failure(let error):
                print("❌ Failed to send friend requests: \(error)")
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
    
    // MARK: - Validation
    static func isOnboardingComplete() -> Bool {
        return userName != nil && userBirthdate != nil && !userHobbies.isEmpty
    }

    static func completeOnboarding(completion: @escaping (Bool) -> Void) {
        if isOnboardingComplete() {
            print("📱 Starting onboarding completion")
            // Note: We're already on the pluggingIn screen, so no need to navigate there
            
            // Move all heavy operations to background
            DispatchQueue.global(qos: .userInitiated).async {
                // First upload all images
                let group = DispatchGroup()
                var uploadError: Error?
                
                for (image, isProfilePic) in getAllImages() {
                    group.enter()
                    guard let data = image.jpegData(compressionQuality: 0.8) else {
                        print("❌ Failed to convert image to JPEG data")
                        group.leave()
                        continue
                    }
                    
                    UserImage.upload(imageData: data, isProfilePic: isProfilePic) { result in
                        switch result {
                        case .success:
                            print("✅ Image uploaded successfully")
                            break
                        case .failure(let error):
                            print("❌ Image upload failed: \(error)")
                            uploadError = error
                        }
                        group.leave()
                    }
                }
                
                group.wait() // Wait for all uploads to complete
                
                // Check for upload errors
                if let error = uploadError {
                    print("❌ Upload error occurred: \(error)")
                    Task { @MainActor in
                        AppController.shared.errorMessage = "Failed to upload images: \(error.localizedDescription)"
                        completion(false)
                    }
                    return
                }
                
                print("📱 Images uploaded successfully, proceeding with onboarding completion")
                
                // Then complete onboarding
                makeOnboardingCompleteRequest { success in
                    print("📱 Onboarding completion result: \(success)")
                    if success {
                        // Send friend requests if any
                        if !pendingFriendRequests.isEmpty {
                            print("📱 About to send friend requests: \(pendingFriendRequests)")
                            sendPendingFriendRequests { friendRequestSuccess in
                                print("📱 Friend request result: \(friendRequestSuccess)")
                                DispatchQueue.main.async {
                                    if friendRequestSuccess {
                                        print("✅ All operations completed successfully")
                                        Task { @MainActor in
                                        AppController.shared.hasCompletedOnboarding = true
                                        clearImages() // Clear stored images after successful upload
                                        }
                                    } else {
                                        print("❌ Friend request sending failed")
                                        Task { @MainActor in
                                        AppController.shared.errorMessage = "Failed to send friend requests"
                                        }
                                    }
                                    completion(friendRequestSuccess)
                                }
                            }
                        } else {
                            print("📱 No friend requests to send")
                            DispatchQueue.main.async {
                                print("✅ Onboarding completed without friend requests")
                                Task { @MainActor in
                                AppController.shared.hasCompletedOnboarding = true
                                clearImages() // Clear stored images after successful upload
                                }
                                completion(true)
                            }
                        }
                    } else {
                        print("❌ Onboarding completion failed")
                        DispatchQueue.main.async {
                            completion(false)
                        }
                    }
                }
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
            endpoint: apiOnboardPath,
            parameters: parameters
        ) { (result: Result<OnboardResponse, NetworkError>) in
            switch result {
            case .success(let response):
                print("Onboarding complete: \(response.message)")
                completion(true)
            case .failure(let error):
                Task { @MainActor in
                AppController.shared.errorMessage = "Onboarding failed: \(error.localizedDescription)"
                }
                completion(false)
            }
        }
    }
}
