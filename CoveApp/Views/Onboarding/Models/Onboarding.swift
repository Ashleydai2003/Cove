//
//  Onboarding.swift
//  Cove
//
//  Created by Ashley Dai on 5/13/25.
//

import Foundation

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

    static func storeMoreAboutYou(job: String, workLocation: String, relationStatus: String, interestedInto: String) -> Void {
        userJob = job
        userWorkLocation = workLocation
        userRelationStatus = relationStatus
        userInterestedInto = interestedInto
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
            AppController.shared.path = [.pluggingIn]
            makeOnboardingCompleteRequest { success in
                if success {
                    AppController.shared.hasCompletedOnboarding = true
                    // TODO: navigate to home page
                    AppController.shared.path = [.profile]
                }
                completion(success)
            }
        } else {
            AppController.shared.errorMessage = "Onboarding process incomplete"
            AppController.shared.path = [.mutuals]
            completion(false)
        }
    }

    /// Response model for onboard API
    struct OnboardResponse: Decodable {
        let message: String
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
            "sexuality": userInterestedInto ?? ""
        ]
        
        NetworkManager.shared.post(
            endpoint: apiOnboardPath,
            parameters: parameters
        ) { (result: Result<OnboardResponse, NetworkError>) in
            switch result {
            case .success(let response):
                print("Onboarding complete: \(response.message)")
                // Update onboarding state
                AppController.shared.hasCompletedOnboarding = true
                completion(true)
            case .failure(let error):
                AppController.shared.errorMessage = "Onboarding failed: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
}
