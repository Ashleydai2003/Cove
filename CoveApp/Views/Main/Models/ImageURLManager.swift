import Foundation

actor ImageURLManager {
    static let shared = ImageURLManager()

    private var urlCache: [String: (url: URL, expiryDate: Date)] = [:]
    private let refreshThreshold: TimeInterval = 300 // 5 minutes before expiry

    private init() {}

    func getImageURL(for key: String, fetchURL: @escaping () async throws -> URL) async throws -> URL {
        // Check if we have a cached URL that's still valid
        if let cached = urlCache[key], cached.expiryDate > Date() {
            // If URL is close to expiring, refresh it in the background
            if cached.expiryDate.timeIntervalSinceNow < refreshThreshold {
                Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        let newURL = try await fetchURL()
                        await self.updateCache(key: key, url: newURL)
                    } catch {
                        Log.debug("Background URL refresh failed: \(error)")
                    }
                }
            }
            return cached.url
        }

        // No valid cached URL, fetch a new one
        let newURL = try await fetchURL()
        urlCache[key] = (url: newURL, expiryDate: Date().addingTimeInterval(3600))
        return newURL
    }

    private func updateCache(key: String, url: URL) {
        urlCache[key] = (url: url, expiryDate: Date().addingTimeInterval(3600))
    }

    func clearCache() {
        urlCache.removeAll()
    }
}
