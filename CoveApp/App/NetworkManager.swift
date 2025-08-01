import Foundation
import FirebaseAuth

// Lightweight logging helper
import os

/// NetworkManager: Handles all API requests for the app
class NetworkManager {
    /// Singleton instance for global access
    static let shared = NetworkManager()

    /// API base URL - automatically switches between local dev and production
    private let apiBaseURL = AppConstants.API.baseURL

    /// Private initializer to enforce singleton pattern
    private init() {
        // Minimal initialization logging
        Log.critical("NetworkManager initialized", category: "network")
    }

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
        // Log request with context
        Log.network("GET request started", endpoint: endpoint, method: "GET")

        // Get current Firebase token
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                Log.error("Auth error: \(error.localizedDescription) | Error: \(error)", category: "network")
                CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "GET")
                completion(.failure(.authError(error)))
                return
            }

            guard let token = token else {
                Log.error("Missing auth token", category: "network")
                CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 1, message: "Missing auth token", context: "GET \(endpoint)")
                completion(.failure(.missingToken))
                return
            }

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
                Log.error("Invalid URL: \(self.apiBaseURL)\(endpoint)", category: "network")
                CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 2, message: "Invalid URL", context: "GET \(endpoint)")
                completion(.failure(.invalidURL))
                return
            }

            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Make the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        Log.error("Network error: \(error.localizedDescription)", category: "network")
                        CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "GET")
                        completion(.failure(.networkError(error)))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        Log.error("Invalid response (no HTTP)", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 3, message: "Invalid response (no HTTP)", context: "GET \(endpoint)")
                        completion(.failure(.invalidResponse))
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        Log.error("Server error \(httpResponse.statusCode)", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: httpResponse.statusCode, message: "Server error \(httpResponse.statusCode)", context: "GET \(endpoint)")
                        completion(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }

                    guard let data = data else {
                        Log.error("No data received", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 4, message: "No data received", context: "GET \(endpoint)")
                        completion(.failure(.noData))
                        return
                    }

                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        Log.network("GET request successful", endpoint: endpoint, method: "GET")
                        completion(.success(decodedResponse))
                    } catch {
                        Log.error("Decoding error: \(error.localizedDescription)", category: "network")
                        CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "GET")
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
        Log.network("POST request started", endpoint: endpoint, method: "POST")

        // Get current Firebase token
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                Log.error("Auth error: \(error.localizedDescription) | Error: \(error)", category: "network")
                CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "POST")
                completion(.failure(.authError(error)))
                return
            }

            guard let token = token else {
                Log.error("Missing auth token", category: "network")
                CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 1, message: "Missing auth token", context: "POST \(endpoint)")
                completion(.failure(.missingToken))
                return
            }

            // Create URL
            guard let url = URL(string: "\(self.apiBaseURL)\(endpoint)") else {
                Log.error("Invalid URL: \(self.apiBaseURL)\(endpoint)", category: "network")
                CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 2, message: "Invalid URL", context: "POST \(endpoint)")
                completion(.failure(.invalidURL))
                return
            }

            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create request body
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                Log.error("Encoding error: \(error.localizedDescription)", category: "network")
                CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "POST")
                completion(.failure(.encodingError(error)))
                return
            }

            // Make the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        Log.error("Network error: \(error.localizedDescription)", category: "network")
                        CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "POST")
                        completion(.failure(.networkError(error)))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        Log.error("Invalid response (no HTTP)", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 3, message: "Invalid response (no HTTP)", context: "POST \(endpoint)")
                        completion(.failure(.invalidResponse))
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        Log.error("Server error \(httpResponse.statusCode)", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: httpResponse.statusCode, message: "Server error \(httpResponse.statusCode)", context: "POST \(endpoint)")
                        completion(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }

                    guard let data = data else {
                        Log.error("No data received", category: "network")
                        CrashlyticsHandler.recordCustomError(domain: "CoveApp.Network", code: 4, message: "No data received", context: "POST \(endpoint)")
                        completion(.failure(.noData))
                        return
                    }

                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        Log.network("POST request successful", endpoint: endpoint, method: "POST")
                        completion(.success(decodedResponse))
                    } catch {
                        Log.error("Decoding error: \(error.localizedDescription)", category: "network")
                        CrashlyticsHandler.recordNetworkError(error, endpoint: endpoint, method: "POST")
                        completion(.failure(.decodingError(error)))
                    }
                }
            }

            task.resume()
        }
    }

    // MARK: - Helper Methods for Refactored PUT
    private func getFirebaseToken(completion: @escaping (Result<String, NetworkError>) -> Void) {
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                Log.error("Auth error: \(error.localizedDescription) | Error: \(error)", category: "network")
                completion(.failure(.authError(error)))
                return
            }
            guard let token = token else {
                completion(.failure(.missingToken))
                return
            }
            completion(.success(token))
        }
    }

    private func createRequest(endpoint: String, token: String, parameters: [String: Any], method: String) -> Result<URLRequest, NetworkError> {
        guard let url = URL(string: "\(self.apiBaseURL)\(endpoint)") else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return .failure(.encodingError(error))
        }
        return .success(request)
    }

    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, NetworkError>) -> Void) {
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

    /// Makes a PUT request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/open-invite")
    ///   - parameters: Request body parameters
    ///   - completion: Callback with the decoded response or error
    func put<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        Log.debug("PUT \(endpoint) – body keys: \(parameters.keys)", category: "network")
        getFirebaseToken { [weak self] tokenResult in
            guard let self = self else { return }
            switch tokenResult {
            case .failure(let error):
                Log.error("Auth error: \(error)", category: "network")
                completion(.failure(error))
            case .success(let token):
                switch self.createRequest(endpoint: endpoint, token: token, parameters: parameters, method: "PUT") {
                case .failure(let error):
                    Log.error("Request creation error: \(error)", category: "network")
                    completion(.failure(error))
                case .success(let request):
                    Log.debug("Sending PUT request...", category: "network")
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        DispatchQueue.main.async {
                            self.handleResponse(data: data, response: response, error: error, completion: completion)
                        }
                    }
                    task.resume()
                }
            }
        }
    }

    /// Makes a DELETE request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/reject-invite")
    ///   - parameters: Request body parameters
    ///   - completion: Callback with the decoded response or error
    func delete<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        Log.debug("DELETE Request - Endpoint: \(endpoint)", category: "network")
        Log.debug("Request Body: \(parameters)", category: "network")

        // Get current Firebase token
        Auth.auth().currentUser?.getIDToken { token, error in
            if let error = error {
                Log.error("Auth error: \(error.localizedDescription) | Error: \(error)", category: "network")
                completion(.failure(.authError(error)))
                return
            }

            guard let token = token else {
                Log.error("Missing auth token", category: "network")
                completion(.failure(.missingToken))
                return
            }

            Log.debug("Auth token received", category: "network")

            // Create URL
            guard let url = URL(string: "\(self.apiBaseURL)\(endpoint)") else {
                Log.error("Invalid URL: \(self.apiBaseURL)\(endpoint)", category: "network")
                completion(.failure(.invalidURL))
                return
            }

            Log.debug("Request URL: \(url.absoluteString)", category: "network")

            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create request body
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                Log.debug("Request Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Unable to decode body")", category: "network")
            } catch {
                Log.error("Encoding error: \(error.localizedDescription)", category: "network")
                completion(.failure(.encodingError(error)))
                return
            }

            Log.debug("Sending DELETE request...", category: "network")

            // Make the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        Log.error("Network error: \(error.localizedDescription)", category: "network")
                        completion(.failure(.networkError(error)))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        Log.error("Invalid response (no HTTP)", category: "network")
                        completion(.failure(.invalidResponse))
                        return
                    }

                    Log.debug("Response status: \(httpResponse.statusCode)", category: "network")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        Log.error("Server error \(httpResponse.statusCode)", category: "network")
                        completion(.failure(.serverError(httpResponse.statusCode)))
                        return
                    }

                    guard let data = data else {
                        Log.error("No data received", category: "network")
                        completion(.failure(.noData))
                        return
                    }

                    #if DEBUG
                    if let jsonString = String(data: data, encoding: .utf8) {
                        Log.debug("Raw JSON: \(jsonString)", category: "network")
                    }
                    #endif

                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        Log.debug("Successfully decoded response", category: "network")
                        completion(.success(decodedResponse))
                    } catch {
                        Log.error("Decoding error: \(error.localizedDescription)", category: "network")
                        Log.debug("Failed to decode response as \(T.self)", category: "network")
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
