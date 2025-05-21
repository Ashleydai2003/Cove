import Foundation
import FirebaseAuth

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
    /// - Parameter completion: Callback with success status
    func sendVerificationCode(completion: @escaping (Bool) -> Void) {
        let fullPhoneNumber = getFullPhoneNumber()
        print("📱 Attempting to send verification code to: \(fullPhoneNumber)")
        
        // Disable reCAPTCHA verification
        // TODO: REMOVE THIS AFTER GETTING TOKEN FOR TESTING!!!!
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase Auth Error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    AppController.shared.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                if let verificationID = verificationID {
                    print("✅ Successfully received verification ID")
                    // Store the full phone number in UserDefaults
                    UserDefaults.standard.set(getFullPhoneNumber(), forKey: "UserPhoneNumber")
                    print("✅ UserDefault set: \(UserDefaults.standard.string(forKey: "UserPhoneNumber") ?? "N/A")")
                    // Store the verification ID in UserDefaults
                    UserDefaults.standard.set(verificationID, forKey: "verification_id")
                    completion(true)
                } else {
                    print("❌ Failed to get verification ID - no error but no ID received")
                    AppController.shared.errorMessage = "Failed to get verification ID"
                    completion(false)
                }
            }
        }
    }
} 
