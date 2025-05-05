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
    
    /// Currently entered phone number
    @Published var phoneNumber: String = ""
    @Published var selectedCountry: Country = Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)
    @Published var path: [OnboardingRoute] = []
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
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
    
    /// Validates if a phone number matches the required pattern
    /// - Parameters:
    ///   - number: Phone number to validate
    ///   - pattern: Required format pattern
    /// - Returns: Boolean indicating if the number is valid
    func isValidPhoneNumber(_ number: String, pattern: String) -> Bool {
        // Input validation
        guard !number.isEmpty else { return false }
        
        let cleanNumber = number.filter { $0.isNumber }
        let requiredDigits = pattern.filter { $0 == "#" }.count
        
        let isValid = cleanNumber.count == requiredDigits
        
        // If the number is valid, store it
        if isValid {
            storePhoneNumber()
        }
        
        return isValid
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
}
