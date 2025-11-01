//
//  VendorOtpVerify.swift
//  Cove
//
//  Vendor OTP verification logic - copied from OtpVerify

import Foundation
import FirebaseAuth

struct VendorOtpVerify {
    /// Verifies the OTP code entered by the vendor user
    /// - Parameters:
    ///   - code: The OTP code to verify
    ///   - vendorController: The vendor controller
    ///   - completion: Callback with success status
    static func verifyOTP(_ code: String, vendorController: VendorController, completion: @escaping (Bool) -> Void) {
        Log.debug("Attempting to verify vendor OTP code")

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: UserDefaults.standard.string(forKey: "vendor_verification_id") ?? "",
            verificationCode: code
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    Log.error("Firebase Auth Error: \(error.localizedDescription)")
                    Log.error("Error details: \(error)")
                    vendorController.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                // Only print user if needed, don't bind unused
                if authResult?.user != nil {
                    Log.debug("Successfully verified OTP and signed in")
                    
                    // Get Firebase ID token for backend authentication
                    authResult?.user.getIDToken { _, error in
                        if error == nil {
                            Log.debug("Firebase ID token obtained successfully")
                        } else if let error = error {
                            Log.error("Error getting Firebase token: \(error.localizedDescription)")
                        }
                    }
                    
                    // Make vendor login request to backend
                    makeVendorLoginRequest(vendorController: vendorController) { success in
                        if success {
                            completion(true)
                        } else {
                            vendorController.errorMessage = "Failed to login to backend"
                            completion(false)
                        }
                    }
                } else {
                    Log.error("Failed to verify OTP - no error but no auth result")
                    vendorController.errorMessage = "Failed to verify OTP"
                    completion(false)
                }
            }
        }
    }

    /// Clears verification state but keeps phone number for resending
    static func clearVerificationState() {
        Log.debug("Clearing vendor verification state")
        UserDefaults.standard.removeObject(forKey: "vendor_verification_id")
        // Keep VendorPhoneNumber for potential resending
    }

    /// Handles authentication failure by resetting relevant state
    static func handleAuthFailure(vendorController: VendorController) {
        // Clear the stored phone number
        Log.debug("Vendor User Default Removed!")
        UserDefaults.standard.removeObject(forKey: "VendorPhoneNumber")

        // Clear the stored verification ID
        UserDefaults.standard.removeObject(forKey: "vendor_verification_id")

        // Reset to phone number entry
        Task { @MainActor in
            vendorController.path = []
        }
    }

    /// Makes a vendor login request to the backend API
    /// - Parameters:
    ///   - vendorController: The vendor controller
    ///   - completion: Callback with success status
    private static func makeVendorLoginRequest(vendorController: VendorController, completion: @escaping (Bool) -> Void) {
        // Use VendorNetworkManager to call /vendor/login
        VendorNetworkManager.shared.vendorLogin { result in
            Task { @MainActor in
                switch result {
                case .success(let loginResponse):
                    Log.debug("Vendor login successful: \(loginResponse.message)")
                    
                    // Update vendor controller with response data
                    vendorController.isAuthenticated = true
                    vendorController.vendorUser = loginResponse.vendorUser
                    
                    // Determine next step based on onboarding status
                    print("🔍 VendorOtpVerify: onboarding=\(loginResponse.vendorUser.onboarding), vendorId=\(loginResponse.vendorUser.vendorId ?? "nil")")
                    
                    if loginResponse.vendorUser.onboarding {
                        // Check if they have a vendor organization
                        if loginResponse.vendorUser.vendorId == nil {
                            // Need to join/create organization
                            print("🔍 VendorOtpVerify: Navigating to codeEntry")
                            vendorController.path.append(.codeEntry)
                        } else {
                            // Have organization, need personal info
                            print("🔍 VendorOtpVerify: Navigating to userDetails")
                            vendorController.path.append(.userDetails)
                        }
                    } else {
                        // Onboarding complete, go to home
                        print("🔍 VendorOtpVerify: Navigating to complete")
                        vendorController.hasCompletedOnboarding = true
                        vendorController.isLoggedIn = true
                        vendorController.path.append(.complete)
                    }
                    
                    completion(true)
                    
                case .failure(let error):
                    Log.error("Vendor backend login error: \(error.localizedDescription)")
                    vendorController.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}

