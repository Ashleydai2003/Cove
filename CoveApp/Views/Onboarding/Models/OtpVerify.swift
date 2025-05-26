import Foundation
import FirebaseAuth

struct OtpVerify {
    /// API base URL and login path
    private static let apiBaseURL = "https://api.coveapp.co"
    private static let apiLoginPath = "/login"
    
    /// Verifies the OTP code entered by the user
    /// - Parameters:
    ///   - code: The OTP code to verify
    ///   - completion: Callback with success status
    static func verifyOTP(_ code: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to verify OTP code")
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: UserDefaults.standard.string(forKey: "verification_id") ?? "",
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase Auth Error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    AppController.shared.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                if let user = authResult?.user {
                    print("✅ Successfully verified OTP and signed in")
                    // Make login request to backend
                    makeLoginRequest { success in
                        if success {
                            completion(true)
                        } else {
                            AppController.shared.errorMessage = "Failed to login to backend"
                            completion(false)
                        }
                    }
                } else {
                    print("❌ Failed to verify OTP - no error but no auth result")
                    AppController.shared.errorMessage = "Failed to verify OTP"
                    completion(false)
                }
            }
        }
    }
    
    /// Handles authentication failure by resetting relevant state
    static func handleAuthFailure() {
        // Clear the stored phone number
        print(("User Default Removed!"))
        UserDefaults.standard.removeObject(forKey: "UserPhoneNumber")
        
        // Clear the stored verification ID
        UserDefaults.standard.removeObject(forKey: "verification_id")
        
        // Reset the navigation path to the phone number entry screen
        AppController.shared.path = [.enterPhoneNumber]
    }
    
    /// Response model for login API
    struct LoginResponse: Decodable {
        let message: String
        let user: UserInfo
    }
    
    /// User info model from login response
    struct UserInfo: Decodable {
        let uid: String
        let onboarding: Bool
    }
    
    /// Makes a login request to the backend API
    /// - Parameters:
    ///   - completion: Callback with success status
    private static func makeLoginRequest(completion: @escaping (Bool) -> Void) {
        // Create request parameters
        let parameters: [String: String] = [
            "phoneNumber": UserDefaults.standard.string(forKey: "UserPhoneNumber") ?? ""
        ]
        
        // Make the request using NetworkManager with explicit type
        NetworkManager.shared.post(
            endpoint: apiLoginPath,
            parameters: parameters
        ) { (result: Result<LoginResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let loginResponse):
                    print("✅ Successfully logged in to backend")
                    
                    // Store user info in UserDefaults
                    UserDefaults.standard.set(loginResponse.user.uid, forKey: "user_id")
                    
                    // Update onboarding state
                    if loginResponse.user.onboarding {
                        AppController.shared.path = [.userDetails]
                    } else {
                        AppController.shared.path = [.pluggingIn]
                        AppController.shared.hasCompletedOnboarding = true
                    }
                    
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Backend login error: \(error.localizedDescription)")
                    AppController.shared.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
