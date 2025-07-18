// Created by Nesib Muhedin

import Foundation
import FirebaseAuth

enum CodeSendResult {
    case success
    case invalidPhoneNumber
    case networkError
    case rateLimited
    case unknownError(String)
}

struct UserPhoneNumber {
    var number: String
    var country: Country

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
        let countryCodeDigits = country.dial_code.filter { $0.isNumber }
        let totalLength = countryCodeDigits.count + cleanNumber.count

        guard totalLength <= country.limit else {
            return false
        }
        return true
    }

    /// Returns the full phone number in E.164 format (e.g., +14155552671)
    func getFullPhoneNumber() -> String {
        // Remove all non-digit characters from the local number
        let cleanLocalNumber = number.filter { $0.isNumber }

        // Combine country code and local number
        let countryCode = country.dial_code.replacingOccurrences(of: "+", with: "")
        return "+" + countryCode + cleanLocalNumber
    }

    /// Sends verification code to the provided phone number
    /// - Parameter completion: Callback with result status
    func sendVerificationCode(completion: @escaping (CodeSendResult) -> Void) {
        let fullPhoneNumber = getFullPhoneNumber()

        // Disable reCAPTCHA verification
        // TODO: REMOVE THIS AFTER GETTING TOKEN FOR TESTING!!!!
        #if DEBUG
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif

        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    Log.error("Firebase Auth Error: \(error.localizedDescription)")
                    AppController.shared.errorMessage = error.localizedDescription
                    let result = self.categorizeFirebaseError(error)
                    completion(result)
                    return
                }

                if let verificationID = verificationID {
                    // Store the full phone number in UserDefaults
                    UserDefaults.standard.set(getFullPhoneNumber(), forKey: "UserPhoneNumber")
                    // Store the verification ID in UserDefaults
                    UserDefaults.standard.set(verificationID, forKey: "verification_id")
                    completion(.success)
                } else {
                    Log.error("Failed to get verification ID - no error but no ID received")
                    AppController.shared.errorMessage = "Failed to get verification ID"
                    completion(.unknownError("Failed to get verification ID"))
                }
            }
        }
    }

    /// Categorizes Firebase errors into user-friendly error types
    /// - Parameter error: The Firebase error
    /// - Returns: Appropriate CodeSendResult
    private func categorizeFirebaseError(_ error: Error) -> CodeSendResult {
        let errorCode = (error as NSError).code
        let errorMessage = error.localizedDescription.lowercased()

        // Firebase Auth error codes
        switch errorCode {
        case 17010: // Invalid phone number
            return .invalidPhoneNumber
        case 17025: // Too many requests
            return .rateLimited
        case 17020: // Network error
            return .networkError
        default:
            // Check error message for common patterns
            if errorMessage.contains("invalid phone number") || errorMessage.contains("phone number") {
                return .invalidPhoneNumber
            } else if errorMessage.contains("too many") || errorMessage.contains("quota") || errorMessage.contains("rate") {
                return .rateLimited
            } else if errorMessage.contains("network") || errorMessage.contains("connection") {
                return .networkError
            } else {
                return .unknownError(error.localizedDescription)
            }
        }
    }
}
