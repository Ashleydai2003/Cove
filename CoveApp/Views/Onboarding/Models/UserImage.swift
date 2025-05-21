//
//  UserImage.swift
//  Cove
//

import Foundation

struct UserImage {
    // MARK: - Configuration
    private static let baseURL = "https://api.coveapp.co"
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
    ///   - completion: called with success or failure
    static func upload(
        imageData: Data,
        isProfilePic: Bool,
        completion: @escaping (Result<UploadResponse, Error>) -> Void
    ) {
        // Base64-encode the image and build JSON body
        let base64 = imageData.base64EncodedString()
        let parameters: [String: Any] = [
            "data": base64,
            "isProfilePic": isProfilePic
        ]
        
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
    
    // MARK: - Errors
    
    enum APIError: Error {
        case invalidURL
        case serverError
    }
}
