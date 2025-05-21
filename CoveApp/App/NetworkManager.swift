import Foundation
import FirebaseAuth

/// NetworkManager: Handles all API requests for the app
class NetworkManager {
    /// Singleton instance for global access
    static let shared = NetworkManager()
    
    /// API base URL
    private let apiBaseURL = "https://api.coveapp.co"
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Makes a GET request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/profile")
    ///   - parameters: Query parameters to append to the URL
    ///   - completion: Callback with the decoded response or error
    func get<T: Decodable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        print("🌐 GET Request - Endpoint: \(endpoint)")
        if let params = parameters {
            print("📝 Query Parameters: \(params)")
        }
        
        // Get current Firebase token
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                completion(.failure(.authError(error)))
                return
            }
            
            guard let token = token else {
                print("❌ Missing Auth Token")
                completion(.failure(.missingToken))
                return
            }
            
            print("🔑 Auth Token received")
            
            // Create base URL
            var urlComponents = URLComponents(string: "\(self.apiBaseURL)\(endpoint)")
            
            // Add query parameters if provided
            if let parameters = parameters {
                urlComponents?.queryItems = parameters.map { key, value in
                    URLQueryItem(name: key, value: String(describing: value))
                }
            }
            
            // Create URL
            guard let url = urlComponents?.url else {
                print("❌ Invalid URL: \(self.apiBaseURL)\(endpoint)")
                completion(.failure(.invalidURL))
                return
            }
            
            print("🔗 Request URL: \(url.absoluteString)")
            
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            print("📤 Sending GET request...")
            
            // Make the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Network Error: \(error.localizedDescription)")
                        completion(.failure(.networkError(error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid Response: No HTTP response")
                        completion(.failure(.invalidResponse))
                        return
                    }
                    
                    print("📥 Response Status: \(httpResponse.statusCode)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ Server Error: \(httpResponse.statusCode)")
                        completion(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ No Data Received")
                        completion(.failure(.noData))
                        return
                    }
                    
                    print("📦 Received Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
                    
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        print("✅ Successfully decoded response")
                        completion(.success(decodedResponse))
                    } catch {
                        print("❌ Decoding Error: \(error.localizedDescription)")
                        completion(.failure(.decodingError(error)))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    /// Makes a POST request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/login")
    ///   - parameters: Request body parameters
    ///   - completion: Callback with the decoded response or error
    func post<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        print("🌐 POST Request - Endpoint: \(endpoint)")
        print("📝 Request Body: \(parameters)")
        
        // Get current Firebase token
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                print("❌ Auth Error: \(error.localizedDescription)")
                completion(.failure(.authError(error)))
                return
            }
            
            guard let token = token else {
                print("❌ Missing Auth Token")
                completion(.failure(.missingToken))
                return
            }
            
            print("🔑 Auth Token received")
            
            // Create URL
            guard let url = URL(string: "\(self.apiBaseURL)\(endpoint)") else {
                print("❌ Invalid URL: \(self.apiBaseURL)\(endpoint)")
                completion(.failure(.invalidURL))
                return
            }
            
            print("🔗 Request URL: \(url.absoluteString)")
            
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Create request body
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                print("📦 Request Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Unable to decode body")")
            } catch {
                print("❌ Encoding Error: \(error.localizedDescription)")
                completion(.failure(.encodingError(error)))
                return
            }
            
            print("📤 Sending POST request...")
            
            // Make the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Network Error: \(error.localizedDescription)")
                        completion(.failure(.networkError(error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid Response: No HTTP response")
                        completion(.failure(.invalidResponse))
                        return
                    }
                    
                    print("📥 Response Status: \(httpResponse.statusCode)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ Server Error: \(httpResponse.statusCode)")
                        completion(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ No Data Received")
                        completion(.failure(.noData))
                        return
                    }
                    
                    print("📦 Received Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
                    
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        print("✅ Successfully decoded response")
                        completion(.success(decodedResponse))
                    } catch {
                        print("❌ Decoding Error: \(error.localizedDescription)")
                        completion(.failure(.decodingError(error)))
                    }
                }
            }
            
            task.resume()
        }
    }
}

/// Network error types
enum NetworkError: Error {
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case noData
    case decodingError(Error)
    case authError(Error)
    case missingToken
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError(let error):
            return "Error encoding request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Error processing server response: \(error.localizedDescription)"
        case .authError(let error):
            return "Authentication error: \(error.localizedDescription)"
        case .missingToken:
            return "Missing authentication token"
        }
    }
} 