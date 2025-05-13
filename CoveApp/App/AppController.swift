//
//  AppController.swift
//  Cove
//
//  Created by Ashley Dai on 4/28/25.
//

import SwiftUI
import FirebaseAuth

enum OnboardingRoute: Hashable {
    case enterPhoneNumber
    case otpVerify
    case userDetails
    case birthdate
    case hobbies
    case bio
    case profilePics
    case mutuals
    case finished
}

/// AppController: Manages shared application state and business logic
/// - Handles authentication state
/// - Manages shared data between views
/// - Provides utility functions for data formatting and validation
class AppController: ObservableObject {
    /// Singleton instance for global access
    static let shared = AppController()
    
    /// API base URL and login path
    private let apiBaseURL = "https://api.coveapp.co"
    private let apiLoginPath = "/login"
    
    /// Currently entered phone number
    @Published var phoneNumber: String = ""
    @Published var selectedCountry: Country = Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)
    @Published var path: [OnboardingRoute] = []
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var verificationID: String = ""
    @Published var errorMessage: String = ""
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Formats a phone number according to the provided pattern
    /// - Parameters:
    ///   - number: Raw phone number string
    ///   - pattern: Format pattern (e.g., "### ### ####")
    /// - Returns: Formatted phone number string
    func formatPhoneNumber(_ number: String, pattern: String) -> String {
        // Input validation
        guard !number.isEmpty else { return "" }
        
        // Remove all non-digit characters
        let cleanNumber = number.filter { $0.isNumber }
        
        // Get the maximum number of digits allowed by the pattern
        let maxDigits = pattern.filter { $0 == "#" }.count
        
        // Truncate the number if it exceeds the pattern's limit
        let truncatedNumber = String(cleanNumber.prefix(maxDigits))
        
        var result = ""
        var numberIndex = truncatedNumber.startIndex
        
        // Iterate through the pattern
        for patternChar in pattern {
            if patternChar == "#" {
                if numberIndex < truncatedNumber.endIndex {
                    result.append(truncatedNumber[numberIndex])
                    numberIndex = truncatedNumber.index(after: numberIndex)
                }
            } else {
                // Only add the separator if we have more digits to come
                if numberIndex < truncatedNumber.endIndex {
                    result.append(patternChar)
                }
            }
        }
        
        return result
    }
    
    /// Validates if a phone number matches the required pattern and doesn't exceed the country's limit
    /// - Parameters:
    ///   - number: Phone number to validate
    ///   - pattern: Required format pattern
    /// - Returns: Boolean indicating if the number is valid
    func isValidPhoneNumber(_ number: String, pattern: String) -> Bool {
        // Input validation
        guard !number.isEmpty else { return false }
        
        // Get clean number (digits only)
        let cleanNumber = number.filter { $0.isNumber }
        let requiredDigits = pattern.filter { $0 == "#" }.count
        
        // Check if the number matches the pattern's digit count
        guard cleanNumber.count == requiredDigits else { return false }
        
        // Check if the total length (country code + number) doesn't exceed the limit
        let countryCodeDigits = selectedCountry.dial_code.filter { $0.isNumber }
        let totalLength = countryCodeDigits.count + cleanNumber.count
        
        guard totalLength <= selectedCountry.limit else {
            errorMessage = "Phone number exceeds maximum length for this country"
            return false
        }
        
        // If the number is valid, store it
        storePhoneNumber()
        
        return true
    }
    
    /// Returns the full phone number in E.164 format (e.g., +14155552671)
    func getFullPhoneNumber() -> String {
        // Remove all non-digit characters from the local number
        let cleanLocalNumber = phoneNumber.filter { $0.isNumber }
        
        // Combine country code and local number
        let countryCode = selectedCountry.dial_code.replacingOccurrences(of: "+", with: "")
        return "+" + countryCode + cleanLocalNumber
    }
    
    /// Stores the phone number in a standardized format
    func storePhoneNumber() {
        // Get the full phone number in E.164 format
        let fullNumber = getFullPhoneNumber()
        
        // Store the full number in UserDefaults
        UserDefaults.standard.set(fullNumber, forKey: "storedPhoneNumber")
    }
    
    /// Handles authentication failure by resetting relevant state
    func handleAuthFailure() {
        // Clear the stored phone number
        UserDefaults.standard.removeObject(forKey: "storedPhoneNumber")
        
        // Reset the phone number input
        phoneNumber = ""
        
        // Reset the navigation path to the phone number entry screen
        path = [.enterPhoneNumber]
    }
    
    /// Resets the controller to its initial state
    func reset() {
        // Clear all stored data
        UserDefaults.standard.removeObject(forKey: "storedPhoneNumber")
        hasCompletedOnboarding = false
        
        // Reset all published properties
        phoneNumber = ""
        selectedCountry = Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)
        path = []
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    /// Sends verification code to the provided phone number
    func sendVerificationCode(completion: @escaping (Bool) -> Void) {
        let fullPhoneNumber = getFullPhoneNumber()
        print("📱 Attempting to send verification code to: \(fullPhoneNumber)")
        
        // Disable reCAPTCHA verification
        // TODO: REMOVE THIS AFTER GETTING TOKEN FOR TESTING!!!!
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase Auth Error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                if let verificationID = verificationID {
                    print("✅ Successfully received verification ID")
                    self?.verificationID = verificationID
                    completion(true)
                } else {
                    print("❌ Failed to get verification ID - no error but no ID received")
                    self?.errorMessage = "Failed to get verification ID"
                    completion(false)
                }
            }
        }
    }
    
    /// Verifies the OTP code entered by the user
    func verifyOTP(_ code: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to verify OTP code")
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase Auth Error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                if let user = authResult?.user {
                    print("✅ Successfully verified OTP and signed in")
                    // Get the ID token
                    user.getIDToken { token, error in
                        if let error = error {
                            print("❌ Error getting ID token: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to get ID token"
                            completion(false)
                            return
                        }
                        
                        if let token = token {
                            print("✅ Successfully got ID token")
                            // TODO: REMOVE THIS AFTER GETTING TOKEN FOR TESTING!!!!
                            print("🔑 TOKEN VALUE: \(token)")
                            // Store the token for future API calls
                            UserDefaults.standard.set(token, forKey: "firebase_id_token")
                            
                            // Make login request to backend
                            self?.makeLoginRequest(token: token) { success in
                                if success {
                                    // If user is new, start onboarding
                                    if UserDefaults.standard.bool(forKey: "is_new_user") {
                                        self?.path = [.userDetails]
                                    } else {
                                        // TODO: hasCompletedOnboarding seems not elegant, we should just get back
                                        // from the api what path we should be on and continue from there
                                        self?.path = [.finished]
                                        self?.hasCompletedOnboarding = true
                                    }
                                }
                                completion(success)
                            }
                        } else {
                            print("❌ No ID token received")
                            self?.errorMessage = "Failed to get ID token"
                            completion(false)
                        }
                    }
                } else {
                    print("❌ Failed to verify OTP - no error but no auth result")
                    self?.errorMessage = "Failed to verify OTP"
                    completion(false)
                }
            }
        }
    }
    
    /// Makes a login request to the backend API
    /// - Parameters:
    ///   - token: Firebase ID token
    ///   - completion: Callback with success status
    private func makeLoginRequest(token: String, completion: @escaping (Bool) -> Void) {
        // Create request parameters
        let parameters: [String: String] = [
            "phoneNumber": getFullPhoneNumber()
        ]
        
        // Make the request using NetworkManager with explicit type
        NetworkManager.shared.post(
            endpoint: apiLoginPath,
            token: token,
            parameters: parameters
        ) { [weak self] (result: Result<LoginResponse, NetworkError>) in
            switch result { 
            case .success(let loginResponse):
                print("✅ Successfully logged in to backend")
                
                // Store user info in UserDefaults
                UserDefaults.standard.set(loginResponse.user.uid, forKey: "user_id")
                UserDefaults.standard.set(loginResponse.user.isNewUser, forKey: "is_new_user")
                
                // TODO: Handle onboarding progress 
              
                // Current simple onboarding flow based on isNewUser
                if loginResponse.user.isNewUser {
                    self?.path = [.userDetails]
                } else {
                    self?.hasCompletedOnboarding = true
                }
                
                completion(true)
                
            case .failure(let error):
                print("❌ Backend login error: \(error.localizedDescription)")
                self?.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    /// Response model for login API
    struct LoginResponse: Decodable {
        let message: String
        let user: UserInfo
    }
    
    /// User info model from login response
    struct UserInfo: Decodable {
        let uid: String
        let isNewUser: Bool
    }
    
    // /// Onboarding progress model
    // private struct OnboardingProgress: Codable {
    //     let currentStep: String
    //     let completedSteps: [String]
    //     let hasCompletedOnboarding: Bool
    // }
}
