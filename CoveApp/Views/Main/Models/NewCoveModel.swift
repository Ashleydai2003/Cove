//
//  NewCoveModel.swift
//  Cove
//
//  Created by Assistant

import SwiftUI
import Foundation

/// Model for creating new coves, following MVVM pattern
@MainActor
class NewCoveModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var location: String?
    @Published var coverPhoto: UIImage?
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // Sheet States
    @Published var showImagePicker: Bool = false
    @Published var showLocationPicker: Bool = false

    // Invite Properties
    @Published var invitePhoneNumbers: [String] = []
    @Published var inviteMessage: String = ""

    // MARK: - Computed Properties
    var isFormValid: Bool {
        return !name.isEmpty && location != nil
    }

    var hasInvites: Bool {
        return !invitePhoneNumbers.isEmpty
    }

    // MARK: - Methods

    /// Resets all form fields to their initial state
    func resetForm() {
        name = ""
        description = ""
        location = nil
        coverPhoto = nil
        isSubmitting = false
        errorMessage = nil
        showImagePicker = false
        showLocationPicker = false
        invitePhoneNumbers = []
        inviteMessage = ""
    }

    /// Stores phone numbers and message from SendInvitesView
    func storeInviteData(phoneNumbers: [String], message: String) {
        // Store the formatted phone numbers (these are already validated and formatted)
        invitePhoneNumbers = phoneNumbers
        inviteMessage = message

        Log.debug("Stored invite data: count=\(phoneNumbers.count)")
    }

    /// Clears all stored invite data
    func clearInviteData() {
        invitePhoneNumbers = []
        inviteMessage = ""
        Log.debug("Cleared invite data")
    }

    /// Submits the cove to the backend and optionally sends invites
    func submitCove(completion: @escaping (Bool) -> Void) {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            completion(false)
            return
        }

        guard self.location != nil else {
            errorMessage = "Location is required"
            completion(false)
            return
        }

        isSubmitting = true
        errorMessage = nil

        // Step 1: Create the cove first
        createCove { [weak self] success, coveId in
            guard let self = self else { 
                Log.error("NewCoveModel: Self was deallocated during cove creation")
                completion(false)
                return 
            }

            if success, let coveId = coveId {
                // Step 2: Send invites if there are any
                if self.hasInvites {
                    self.sendInvites(coveId: coveId) { inviteSuccess in
                        DispatchQueue.main.async {
                            self.isSubmitting = false
                            if inviteSuccess {
                                Log.debug("Cove created and invites sent successfully")
                            } else {
                                Log.error("Cove created but invites failed to send")
                                // Still consider it a success since cove was created
                            }
                            self.resetForm()
                            completion(true)
                        }
                    }
                } else {
                    // No invites to send
                    DispatchQueue.main.async {
                        self.isSubmitting = false
                        self.resetForm()
                        completion(true)
                    }
                }
            } else {
                // Cove creation failed
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    completion(false)
                }
            }
        }
    }

    /// Creates the cove via API
    private func createCove(completion: @escaping (Bool, String?) -> Void) {
        // Prepare parameters - description is optional, coverPhoto is optional
        var params: [String: Any] = [
            "name": name,
            "location": location!
        ]

        // Add description if not empty
        if !description.isEmpty {
            params["description"] = description
        }

        // Add cover photo if provided
        if let image = coverPhoto,
           let coverPhotoData = image.jpegData(compressionQuality: 0.8) {
            params["coverPhoto"] = coverPhotoData.base64EncodedString()
        }

        Log.debug("Creating cove with params: \(params.keys)")

        NetworkManager.shared.post(
            endpoint: "/create-cove",
            parameters: params
        ) { [weak self] (result: Result<CreateCoveResponse, NetworkError>) in
            guard let self = self else {
                Log.error("NewCoveModel: Self was deallocated during network call")
                completion(false, nil)
                return
            }
            
            switch result {
            case .success(let response):
                Log.debug("Cove created successfully")
                completion(true, response.cove.id)
            case .failure(let error):
                Log.error("Cove creation failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create cove: \(error.localizedDescription)"
                }
                completion(false, nil)
            }
        }
    }

    /// Sends invites using the SendInvitesModel
    private func sendInvites(coveId: String, completion: @escaping (Bool) -> Void) {
        Log.debug("Sending invites for cove: \(coveId)")

        // Prepare request body
        var requestBody: [String: Any] = [
            "coveId": coveId,
            "phoneNumbers": invitePhoneNumbers
        ]

        // Add message if not empty
        if !inviteMessage.isEmpty {
            requestBody["message"] = inviteMessage
        }

        NetworkManager.shared.post(
            endpoint: "/send-invite",
            parameters: requestBody
        ) { (result: Result<SendInvitesModel.SendInviteResponse, NetworkError>) in
            switch result {
            case .success(_):
                Log.debug("Invites sent successfully")
                completion(true)
            case .failure(let error):
                Log.error("Invites failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}

// MARK: - Response Models

/// API response for cove creation
struct CreateCoveResponse: Decodable {
    let message: String
    let cove: CreatedCove
}

/// CreatedCove: Used for cove creation responses
struct CreatedCove: Decodable {
    let id: String
    let name: String
    let description: String?
    let location: String
    let createdAt: String
}
