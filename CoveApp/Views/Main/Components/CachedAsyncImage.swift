import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var currentURL: URL?
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // Use ImageURLManager to get a valid URL
        do {
            let validURL = try await ImageURLManager.shared.getImageURL(for: url.absoluteString) {
                // This closure will be called when we need to fetch a new URL
                // For now, we'll just return the original URL since the backend handles pre-signed URLs
                // In the future, we could make an API call here to get a new pre-signed URL
                return url
            }
            
            guard validURL != currentURL else { return }
            currentURL = validURL
            
            isLoading = true
            defer { isLoading = false }
            
            let (data, _) = try await URLSession.shared.data(from: validURL)
            if let image = UIImage(data: data) {
                withTransaction(transaction) {
                    self.image = image
                }
            }
        } catch {
            Log.debug("Error loading image: \(error)")
        }
    }
} 