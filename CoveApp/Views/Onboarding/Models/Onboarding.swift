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
    
    private static let apiBaseURL = "https://api.coveapp.co"
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

    static func completeOnboarding(completion: @escaping (Bool) -> Void) {
        if isOnboardingComplete() {
            print("📱 Starting onboarding completion")
            // Show loading screen immediately
            AppController.shared.path = [.pluggingIn]
            
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
                    DispatchQueue.main.async {
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
                                        AppController.shared.hasCompletedOnboarding = true
                                        clearImages() // Clear stored images after successful upload
                                        AppController.shared.path = [.profile]
                                    } else {
                                        print("❌ Friend request sending failed")
                                        AppController.shared.errorMessage = "Failed to send friend requests"
                                    }
                                    completion(friendRequestSuccess)
                                }
                            }
                        } else {
                            print("📱 No friend requests to send")
                            DispatchQueue.main.async {
                                print("✅ Onboarding completed without friend requests")
                                AppController.shared.hasCompletedOnboarding = true
                                clearImages() // Clear stored images after successful upload
                                AppController.shared.path = [.profile]
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
            AppController.shared.errorMessage = "Onboarding process incomplete"
            AppController.shared.path = [.mutuals]
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
        // TODO: maybe add another guard to check if all fields are filled
        
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
            endpoint: apiOnboardPath,
            parameters: parameters
        ) { (result: Result<OnboardResponse, NetworkError>) in
            switch result {
            case .success(let response):
                print("Onboarding complete: \(response.message)")
                completion(true)
            case .failure(let error):
                AppController.shared.errorMessage = "Onboarding failed: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
}
