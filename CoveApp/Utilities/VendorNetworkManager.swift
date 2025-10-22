//
//  VendorNetworkManager.swift
//  Cove
//
//  Network manager for vendor-related API calls
//

import Foundation
import FirebaseAuth
import UIKit

class VendorNetworkManager {
    static let shared = VendorNetworkManager()
    
    private let baseURL: String
    private let session = URLSession.shared
    
    private init() {
        // Use the same base URL as NetworkManager - automatically switches between dev and production
        baseURL = AppConstants.API.baseURL
    }
    
    // MARK: - Authentication
    
    func vendorLogin(completion: @escaping (Result<VendorLoginResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/login") else {
            completion(.failure(.invalidURL))
            return
        }
        
        makeAuthenticatedRequest(url: url, method: "POST", body: [:], completion: completion)
    }
    
    // MARK: - Onboarding
    
    func validateVendorCode(code: String, completion: @escaping (Result<ValidateVendorCodeResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/validate-code") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let body = ["code": code]
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    func createVendorOrganization(
        organizationName: String,
        website: String?,
        primaryContactEmail: String,
        city: String,
        coverPhoto: UIImage? = nil,
        completion: @escaping (Result<CreateVendorOrganizationResponse, NetworkError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/vendor/create-organization") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var body: [String: Any] = [
            "organizationName": organizationName,
            "primaryContactEmail": primaryContactEmail,
            "city": city
        ]
        
        if let website = website {
            body["website"] = website
        }
        
        // Add cover photo if provided
        if let coverPhoto = coverPhoto,
           let imageData = coverPhoto.jpegData(compressionQuality: 0.8) {
            body["coverPhoto"] = imageData.base64EncodedString()
        }
        
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    func joinVendorOrganization(code: String, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/join-organization") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let body = ["code": code]
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    func completeVendorOnboarding(name: String, profilePhoto: UIImage? = nil, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/onboard") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var body: [String: Any] = ["name": name]
        
        // Add profile photo if provided
        if let profilePhoto = profilePhoto,
           let imageData = profilePhoto.jpegData(compressionQuality: 0.8) {
            body["profilePhoto"] = imageData.base64EncodedString()
        }
        
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    // MARK: - Profile Management
    
    func getVendorProfile(completion: @escaping (Result<VendorProfileResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/profile") else {
            completion(.failure(.invalidURL))
            return
        }
        
        makeAuthenticatedRequest(url: url, method: "GET", body: nil, completion: completion)
    }
    
    func updateVendorProfile(name: String, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/profile-update") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let body = ["name": name]
        makeAuthenticatedRequest(url: url, method: "PUT", body: body, completion: completion)
    }
    
    func rotateVendorCode(completion: @escaping (Result<RotateCodeResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/rotate-code") else {
            completion(.failure(.invalidURL))
            return
        }
        
        makeAuthenticatedRequest(url: url, method: "POST", body: [:], completion: completion)
    }
    
    func getVendorMembers(completion: @escaping (Result<VendorMembersResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/members") else {
            completion(.failure(.invalidURL))
            return
        }
        
        makeAuthenticatedRequest(url: url, method: "GET", body: nil, completion: completion)
    }
    
    // MARK: - Event Creation
    
    func createVendorEvent(
        name: String,
        description: String?,
        date: Date,
        location: String,
        memberCap: Int?,
        ticketPrice: Double?,
        paymentHandle: String?,
        coverPhoto: String?,
        useTieredPricing: Bool,
        pricingTiers: [[String: Any]]?,
        completion: @escaping (Result<VendorCreateEventResponse, NetworkError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/vendor/create-event") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var body: [String: Any] = [
            "name": name,
            "date": ISO8601DateFormatter().string(from: date),
            "location": location,
            "useTieredPricing": useTieredPricing
        ]
        
        if let description = description { body["description"] = description }
        if let memberCap = memberCap { body["memberCap"] = memberCap }
        if let ticketPrice = ticketPrice { body["ticketPrice"] = ticketPrice }
        if let paymentHandle = paymentHandle { body["paymentHandle"] = paymentHandle }
        if let coverPhoto = coverPhoto { body["coverPhoto"] = coverPhoto }
        if let pricingTiers = pricingTiers { body["pricingTiers"] = pricingTiers }
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    // MARK: - Vendor Events
    
    func getVendorEvents(completion: @escaping (Result<VendorEventsResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/events") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                print("❌ Failed to get Firebase token: \(error.localizedDescription)")
                completion(.failure(.authError(error)))
                return
            }
            
            guard let token = token else {
                let authError = NSError(domain: "VendorAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
                completion(.failure(.authError(authError)))
                return
            }
            
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let eventsResponse = try decoder.decode(VendorEventsResponse.self, from: data)
                        completion(.success(eventsResponse))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        completion(.failure(.decodingError(error)))
                    }
                } else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    if let errorMessage = String(data: data, encoding: .utf8) {
                        print("Error message: \(errorMessage)")
                    }
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
            }
            
            task.resume()
        }
    }
    
    // MARK: - Event Details
    
    func deleteVendorEvent(eventId: String, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/event/\(eventId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        makeAuthenticatedRequest(url: url, method: "DELETE", body: nil, completion: completion)
    }
    
    // MARK: - Image Upload
    
    func uploadVendorImage(imageData: Data, isProfilePic: Bool, completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/image") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "data": base64Image,
            "isProfilePic": isProfilePic
        ]
        
        struct ImageUploadResponse: Codable {
            let message: String
            let imageId: String
        }
        
        makeAuthenticatedRequest(url: url, method: "POST", body: body) { (result: Result<ImageUploadResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.imageId))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateVendorImage(imageData: Data, photoId: String, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/vendor/image/update") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "data": base64Image,
            "photoId": photoId
        ]
        
        makeAuthenticatedRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    // MARK: - Helper Methods
    
    private func makeAuthenticatedRequest<T: Decodable>(
        url: URL,
        method: String,
        body: [String: Any]?,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        print("🌐 VendorNetworkManager: Making \(method) request to \(url.absoluteString)")
        
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                print("❌ VendorNetworkManager: Auth error - \(error.localizedDescription)")
                completion(.failure(.authError(error)))
                return
            }
            
            guard let token = token else {
                print("❌ VendorNetworkManager: Missing token")
                completion(.failure(.missingToken))
                return
            }
            
            print("✅ VendorNetworkManager: Got auth token")
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let body = body, method != "GET" {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    print("📤 VendorNetworkManager: Request body - \(body)")
                } catch {
                    print("❌ VendorNetworkManager: Encoding error - \(error)")
                    completion(.failure(.encodingError(error)))
                    return
                }
            }
            
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ VendorNetworkManager: Network error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ VendorNetworkManager: Invalid response")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("📥 VendorNetworkManager: Response status code - \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ VendorNetworkManager: No data in response")
                    completion(.failure(.noData))
                    return
                }
                
                // Print raw response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📄 VendorNetworkManager: Raw response - \(rawString)")
                }
                
                // Handle different status codes
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ VendorNetworkManager: Server error - status \(httpResponse.statusCode)")
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    // Use custom date decoding strategy to handle various ISO8601 formats
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)
                        
                        // Try different date formatters
                        let formatters = [
                            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",  // 2025-10-15T00:22:19.654Z
                            "yyyy-MM-dd'T'HH:mm:ss'Z'",      // 2025-10-15T00:22:19Z
                            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", // 2025-10-15T00:22:19.654321Z
                            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",  // 2025-10-15T00:22:19.654Z
                        ]
                        
                        for formatter in formatters {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = formatter
                            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                            if let date = dateFormatter.date(from: dateString) {
                                return date
                            }
                        }
                        
                        // Fallback to ISO8601 if custom formatters fail
                        let iso8601Formatter = ISO8601DateFormatter()
                        if let date = iso8601Formatter.date(from: dateString) {
                            return date
                        }
                        
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected date string to be ISO8601-formatted, got: \(dateString)"
                            )
                        )
                    }
                    let decodedResponse = try decoder.decode(T.self, from: data)
                    print("✅ VendorNetworkManager: Successfully decoded response")
                    completion(.success(decodedResponse))
                } catch {
                    print("❌ VendorNetworkManager: Decoding error - \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("   Missing key: \(key.stringValue) - \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch for type: \(type) - \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("   Value not found for type: \(type) - \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("   Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("   Unknown decoding error")
                        }
                    }
                    completion(.failure(.decodingError(error)))
                }
            }.resume()
        }
    }
}

// MARK: - Supporting Types

struct MessageResponse: Codable {
    let message: String
}

