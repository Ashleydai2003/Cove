//
//  NewPostModel.swift
//  Cove
//
//  Created by Assistant

import SwiftUI
import Foundation
import FirebaseAuth

/// Model for creating new posts, following MVVM pattern
@MainActor
class NewPostModel: ObservableObject {
    // MARK: - Published Properties
    @Published var content: String = ""
    @Published var coveId: String = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties
    var isFormValid: Bool {
        // Content is required and must not exceed 1000 characters
        return !content.isEmpty && content.count <= 1000
    }

    // MARK: - Methods

    /// Resets all form fields to their initial state
    func resetForm() {
        content = ""
        coveId = ""
        isSubmitting = false
        errorMessage = nil
    }

    /// Submits the post to the backend
    func submitPost(completion: @escaping (Bool) -> Void) {
        guard isFormValid else {
            if content.isEmpty {
                errorMessage = "Please enter some content for your post"
            } else if content.count > 1000 {
                errorMessage = "Post content cannot exceed 1000 characters"
            } else {
                errorMessage = "Please fill in all required fields"
            }
            completion(false)
            return
        }

        guard !coveId.isEmpty else {
            errorMessage = "Cove ID is required"
            completion(false)
            return
        }

        isSubmitting = true
        errorMessage = nil

        // Build parameters
        let params: [String: Any] = [
            "content": content,
            "coveId": coveId
        ]

        // Debug: Log the current userId from Firebase Auth
        let firebaseUserId = Auth.auth().currentUser?.uid ?? "no-firebase-user"
        Log.critical("Creating post - Firebase userId: '\(firebaseUserId)', ProfileModel userId: '\(AppController.shared.profileModel.userId)'")

        NetworkManager.shared.post(
            endpoint: "/create-post",
            parameters: params
        ) { (result: Result<CreatePostResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isSubmitting = false

                switch result {
                case .success(let response):
                    Log.debug("✅ Post created successfully: \(response)")
                    self.resetForm()
                    completion(true)
                case .failure(let error):
                    Log.error("Post creation failed: \(error)")
                    self.errorMessage = "Failed to create post: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
}

// MARK: - Response Models

/// API response for post creation
struct CreatePostResponse: Decodable {
    let message: String
    let post: CreatedPost
}

/// CreatedPost: Used for post creation responses
struct CreatedPost: Decodable {
    let id: String
    let content: String
    let coveId: String
    let authorId: String
    let createdAt: String
} 