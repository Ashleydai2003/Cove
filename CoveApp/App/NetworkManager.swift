import Foundation

/// NetworkManager: Handles all API requests for the app
class NetworkManager {
    /// Singleton instance for global access
    static let shared = NetworkManager()
    
    /// API base URL
    private let apiBaseURL = "https://api.coveapp.co"
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Makes a POST request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/login")
    ///   - token: Authentication token for the request
    ///   - parameters: Request body parameters
    ///   - completion: Callback with the decoded response or error
    func post<T: Decodable>(
        endpoint: String,
        token: String,
        parameters: [String: Any],
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) where T: Decodable {
        // Create URL
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create request
        // TODO: Might change this later to be more general for unauthenticated requests
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(.encodingError(error)))
            return
        }
        
        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        
        task.resume()
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
        }
    }
} 