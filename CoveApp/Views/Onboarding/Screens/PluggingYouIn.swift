import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct PluggingYouIn: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController
    @State private var rotation: Double = 0
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
                        plugInUser()
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
    
    private func plugInUser() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        // First, check if user is in onboarding mode
        if appController.profileModel.onboarding {
            print("📱 User is in onboarding mode, completing onboarding...")
            completeOnboarding()
        } else {
            print("📱 User is not in onboarding mode, proceeding with normal flow...")
            fetchUserProfile {
                self.fetchUserCoves()
            }
        }
    }
    
    private func completeOnboarding() {
        Onboarding.completeOnboarding { success in
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                if success {
                    print("✅ Onboarding completed successfully")
                    // After onboarding is complete, fetch profile and coves
                    self.fetchUserProfile {
                        self.fetchUserCoves()
                    }
                } else {
                    print("❌ Onboarding failed")
                    self.errorMessage = "Failed to complete onboarding"
                    // Stay on this screen if onboarding fails
                }
            }
        }
    }
    
    private func fetchUserProfile(completion: @escaping () -> Void) {
        appController.profileModel.fetchProfile { result in
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                switch result {
                case .success(let profileData):
                    print("✅ Profile fetched successfully")
                    
                    // Wait for images to load before proceeding
                    self.appController.profileModel.loadAllImages {
                        DispatchQueue.main.async {
                            // Check if view was cancelled again after images loaded
                            guard !self.isCancelled else { return }
                            
                            print("✅ Profile images loaded successfully")
                            self.isProfileLoaded = true
                            completion()
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Profile fetch failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    // Still mark as loaded even if profile fetch fails
                    self.isProfileLoaded = true
                    completion()
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
                    // Set the coves in the shared CoveFeed instance
                    appController.coveFeed.setUserCoves(response.coves)
                    
                    print("✅ User coves fetched successfully")
                    self.isCovesLoaded = true
                    
                    // Navigate to home after everything is loaded
                    self.navigateToHome()
                    
                case .failure(let error):
                    print("❌ User coves fetch failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch user coves: \(error.localizedDescription)"
                    // Still try to navigate even if coves fetch fails
                    self.isCovesLoaded = true
                    self.navigateToHome()
                }
            }
        }
    }
    
    private func navigateToHome() {
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
                
                if let error = errorMessage {
                    appController.errorMessage = error
                }
                appController.path.append(.home)
            }
        }
    }
}

#Preview {
    PluggingYouIn()
        .environmentObject(AppController.shared)
}
