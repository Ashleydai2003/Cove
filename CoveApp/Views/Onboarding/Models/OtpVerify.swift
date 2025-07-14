import Foundation
import FirebaseAuth

struct OtpVerify {
    /// API base URL and login path
private static let apiBaseURL = AppConstants.API.baseURL
    private static let apiLoginPath = "/login"
    
    /// Verifies the OTP code entered by the user
    /// - Parameters:
    ///   - code: The OTP code to verify
    ///   - completion: Callback with success status
    static func verifyOTP(_ code: String, completion: @escaping (Bool) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: UserDefaults.standard.string(forKey: "verification_id") ?? "",
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    Log.error("Firebase Auth Error: \(error.localizedDescription)")
                    AppController.shared.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                // Only print user if needed, don't bind unused
                if authResult?.user != nil {
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
                    Log.error("Failed to verify OTP - no error but no auth result")
                    AppController.shared.errorMessage = "Failed to verify OTP"
                    completion(false)
                }
            }
        }
    }
    
    /// Handles authentication failure by resetting relevant state
    static func handleAuthFailure() {
        // Clear the stored phone number
        UserDefaults.standard.removeObject(forKey: "UserPhoneNumber")
        
        // Clear the stored verification ID
        UserDefaults.standard.removeObject(forKey: "verification_id")
        
        // Reset the navigation path to the phone number entry screen
        Task { @MainActor in
            AppController.shared.path = [.enterPhoneNumber]
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
        let onboarding: Bool
        let verified: Bool
        let cove: String?
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
                    // Update ProfileModel with onboarding status from login response
                    Task { @MainActor in
                        AppController.shared.profileModel.onboarding = loginResponse.user.onboarding
                        AppController.shared.profileModel.verified = loginResponse.user.verified
                        
                        if loginResponse.user.onboarding {
                            // User is still in onboarding - navigate to appropriate onboarding screen
                            if loginResponse.user.verified {
                                // Admin user - go to admin verification
                                AppController.shared.path.append(.adminVerify)
                                Onboarding.setAdminCove(adminCove: loginResponse.user.cove ?? "create new cove!")
                            } else {
                                // Regular user - go to user details
                                AppController.shared.path.append(.userDetails)
                            }
                        } else {
                            // User has completed onboarding - go to data loading screen
                            AppController.shared.path = [.pluggingIn]
                            AppController.shared.hasCompletedOnboarding = true
                        }
                    }
                    completion(true)
                    
                case .failure(let error):
                    Log.error("Backend login error: \(error.localizedDescription)")
                    AppController.shared.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
