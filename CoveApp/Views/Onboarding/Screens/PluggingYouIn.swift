import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct PluggingYouIn: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController
    @State private var rotation: Double = 0
    @State private var profile: Profile?
    @State private var errorMessage: String?
    @State private var isProfileLoaded = false
    @State private var isCovesLoaded = false
    @State private var animationTimer: Timer?
    @State private var isCancelled = false
    
    var body: some View {
        ZStack {
            // Background image with reduced opacity for better text visibility
            OnboardingBackgroundView(imageName: "login_background")
                .opacity(0.6)
            
            VStack {
                Spacer()
                
                Image("smily")
                    .resizable()
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        startContinuousAnimation()
                        
                        // Start fetching data after initial delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            fetchProfile()
                        }
                    }
                    .onDisappear {
                        stopAnimation()
                        isCancelled = true
                        // Cancel any ongoing profile requests
                        appController.profileModel.cancelAllRequests()
                    }
                
                // App tagline with matching font style
                Text("plugging you in...")
                    .font(.LibreBodoni(size: 35))
                    .foregroundColor(Colors.primaryDark)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func startContinuousAnimation() {
        // Start with initial rotation
        withAnimation(.easeInOut(duration: 0.5)) {
            rotation = 180
        }
        
        // Create a repeating timer for continuous animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                rotation += 180
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func fetchProfile() {
        appController.profileModel.fetchProfile { result in
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                switch result {
                case .success(_):
                    // Profile data is now automatically updated in the ProfileModel
                    print("✅ Profile fetched successfully")
                    isProfileLoaded = true
                    
                    // Fetch user coves after profile is fetched
                    fetchUserCoves()
                    
                    // Check if we can navigate now
                    checkAndNavigate()
                    
                case .failure(let error):
                    print("❌ Profile fetch failed: \(error.localizedDescription)")
                    errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    // Still try to navigate even if profile fetch fails
                    isProfileLoaded = true
                    checkAndNavigate()
                }
            }
        }
    }
    
    private func fetchUserCoves() {
        NetworkManager.shared.get(endpoint: "/user-coves") { (result: Result<UserCovesResponse, NetworkError>) in
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                switch result {
                case .success(let response):
                    // Store cove IDs in UserDefaults
                    let coveIds = response.coves.map { $0.id }
                    UserDefaults.standard.set(coveIds, forKey: "user_cove_ids")
                    print("✅ User coves fetched successfully")
                    isCovesLoaded = true
                    
                    // Check if we can navigate now
                    checkAndNavigate()
                    
                case .failure(let error):
                    print("❌ User coves fetch failed: \(error.localizedDescription)")
                    errorMessage = "Failed to fetch user coves: \(error.localizedDescription)"
                    // Still try to navigate even if coves fetch fails
                    isCovesLoaded = true
                    checkAndNavigate()
                }
            }
        }
    }
    
    private func checkAndNavigate() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        // Only navigate if both profile and coves are loaded (or failed to load)
        if isProfileLoaded && isCovesLoaded {
            // Stop the animation
            stopAnimation()
            
            // Complete the current rotation smoothly
            withAnimation(.easeInOut(duration: 0.5)) {
                rotation = Double(Int(rotation / 180) + 1) * 180.0 // Complete to next 180-degree increment
            }
            
            // Wait for animation to complete, then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                // Check if view was cancelled before navigating
                guard !self.isCancelled else { return }
                
                // Check if images are still loading
                if appController.profileModel.imagesLoading {
                    // Wait a bit more for images to load, but keep animation going
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Check again if cancelled
                        guard !self.isCancelled else { return }
                        
                        if let error = errorMessage {
                            appController.errorMessage = error
                        }
                        appController.path.append(.home)
                    }
                } else {
                    if let error = errorMessage {
                        appController.errorMessage = error
                    }
                    appController.path.append(.home)
                }
            }
        }
    }
}

// Response model for user coves
struct UserCovesResponse: Decodable {
    let coves: [Cove]
}

struct Cove: Decodable {
    let id: String
    let name: String
    let coverPhoto: CoverPhoto?
}
