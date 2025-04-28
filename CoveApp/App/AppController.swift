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
        let replacementCharacter: Character = "#"
        var result = ""
        var numberIndex = number.startIndex
        
        for patternChar in pattern {
            if patternChar == replacementCharacter {
                if numberIndex < number.endIndex {
                    result.append(number[numberIndex])
                    numberIndex = number.index(after: numberIndex)
                }
            } else {
                result.append(patternChar)
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
        let cleanNumber = number.filter { $0.isNumber }
        return cleanNumber.count == pattern.filter { $0 == "#" }.count
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}