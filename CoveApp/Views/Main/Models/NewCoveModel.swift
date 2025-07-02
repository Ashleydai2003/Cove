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
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return !name.isEmpty && location != nil
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
    }
    
    /// Submits the cove to the backend
    func submitCove(completion: @escaping (Bool) -> Void) {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            completion(false)
            return
        }
        
        guard let location = self.location else {
            errorMessage = "Location is required"
            completion(false)
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        // Prepare parameters - description is optional, coverPhoto is optional
        var params: [String: Any] = [
            "name": name,
            "location": location
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
        
        debugPrint("🏠 Creating cove with params: \(params.keys)")
        
        NetworkManager.shared.post(
            endpoint: "/create-cove",
            parameters: params
        ) { (result: Result<CreateCoveResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                switch result {
                case .success(let response):
                    debugPrint("✅ Cove created successfully: \(response)")
                    self.resetForm()
                    completion(true)
                case .failure(let error):
                    debugPrint("❌ Cove creation failed: \(error)")
                    self.errorMessage = "Failed to create cove: \(error.localizedDescription)"
                    completion(false)
                }
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