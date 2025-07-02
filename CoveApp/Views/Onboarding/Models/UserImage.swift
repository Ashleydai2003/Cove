//
//  UserImage.swift
//  Cove
//

import Foundation

struct UserImage {
    // MARK: - Configuration
    private static let baseURL = AppConstants.API.baseURL
    private static let uploadPath = "/userImage"
    
    // MARK: - Response Model
    struct UploadResponse: Decodable {
        let message: String
    }
    
    // MARK: - Public API
    
    /// Posts an image to the server.
    ///
    /// - Parameters:
    ///   - imageData: JPEG-encoded image bytes
    ///   - isProfilePic: true if this is the main profile picture
    ///   - extraImageIndex: index (0 or 1) for extra images, nil for profile picture
    ///   - completion: called with success or failure
    static func upload(
        imageData: Data,
        isProfilePic: Bool,
        extraImageIndex: Int? = nil,
        completion: @escaping (Result<UploadResponse, Error>) -> Void
    ) {
        // Base64-encode the image and build JSON body
        let base64 = imageData.base64EncodedString()
        var parameters: [String: Any] = [
            "data": base64,
            "isProfilePic": isProfilePic
        ]
        
        // Add extraImageIndex if provided (for extra images)
        if let extraImageIndex = extraImageIndex {
            parameters["extraImageIndex"] = extraImageIndex
        }
        
        NetworkManager.shared.post(
            endpoint: uploadPath,
            parameters: parameters
        ) { (result: Result<UploadResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Updates an existing image on the server by replacing it with a new one.
    ///
    /// - Parameters:
    ///   - imageData: JPEG-encoded image bytes
    ///   - photoId: the ID of the photo to replace
    ///   - completion: called with success or failure
    static func updateImage(
        imageData: Data,
        photoId: String,
        completion: @escaping (Result<UploadResponse, Error>) -> Void
    ) {
        // Base64-encode the image and build JSON body
        let base64 = imageData.base64EncodedString()
        let parameters: [String: Any] = [
            "data": base64,
            "photoId": photoId
        ]
        
        NetworkManager.shared.post(
            endpoint: "/userImageUpdate",
            parameters: parameters
        ) { (result: Result<UploadResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Errors
    
    enum APIError: Error {
        case invalidURL
        case serverError
    }
}
