import Foundation
import Kingfisher

/// Simple helper for pre-fetching images using Kingfisher so they are cached before views appear.
struct ImagePrefetcherUtil {
    /// Prefetch a batch of image URLs. Completion fires on main queue when finished (success or fail).
    static func prefetch(urlStrings: [String], completion: (() -> Void)? = nil) {
        let urls = urlStrings.compactMap { URL(string: $0) }
        guard !urls.isEmpty else {
            completion?()
            return
        }
        let prefetcher = ImagePrefetcher(urls: urls, completionHandler: { _, _, _ in
            DispatchQueue.main.async { completion?() }
        })
        prefetcher.start()
    }
    /// Prefetch a single image URL (fire-and-forget).
    static func prefetch(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        KingfisherManager.shared.retrieveImage(with: url, options: [.backgroundDecode]) { _ in }
    }
} 