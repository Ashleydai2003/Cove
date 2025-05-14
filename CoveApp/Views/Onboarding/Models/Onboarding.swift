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
    
    // MARK: - Validation
    static func isOnboardingComplete() -> Bool {
        return userName != nil && userBirthdate != nil && !userHobbies.isEmpty
    }

    static func completeOnboarding() {
        if isOnboardingComplete() {
            makeOnboardingCompleteRequest { success in
                if success {
                    AppController.shared.hasCompletedOnboarding = true
                }
            }
        } else {
            AppController.shared.errorMessage = "Onboarding process incomplete"
        }
    }

    /// Response model for onboard API
    struct OnboardResponse: Decodable {
        let message: String
    }

    private static func makeOnboardingCompleteRequest(completion: @escaping (Bool) -> Void) {

        // TODO: Make API call to complete onboarding

        // TODO: maybe add another guard to check if all fields are filled
        
        // Format date to ISO 8601
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = userBirthdate.map { dateFormatter.string(from: $0) } ?? ""
        
        // Create request parameters
        let parameters: [String: Any] = [
            "name": userName ?? "",
            "birthdate": formattedDate,
            "hobbies": Array(userHobbies)  // Convert Set to Array for JSON serialization
        ]
        
        // TODO: BACKEND API INCOMPLETE, DO NOT CALL THIS ENDPOINT RIGHT NOW
        
        NetworkManager.shared.post(
            endpoint: apiOnboardPath,
            token: token,
            parameters: parameters
        ) { (result: Result<OnboardResponse, NetworkError>) in
            switch result { 
            case .success(let response):
                print("✅ Successfully completed onboarding")
                
                // Update onboarding state
                AppController.shared.path = [.finished]
                AppController.shared.hasCompletedOnboarding = true
                
                completion(true)
                
            case .failure(let error):
                print("❌ Backend onboarding error: \(error.localizedDescription)")
                AppController.shared.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
}
