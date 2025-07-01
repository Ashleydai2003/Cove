import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct PluggingYouIn: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController
    @State private var rotation: Double = 0
    @State private var errorMessage: String?
    @State private var isProfileLoaded = false
    @State private var isCovesLoaded = false
    @State private var isCalendarEventsLoaded = false
    @State private var isUpcomingEventsLoaded = false
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
                self.fetchCalendarEvents()
                self.fetchUpcomingEvents()
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
                        self.fetchCalendarEvents()
                        self.fetchUpcomingEvents()
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
        appController.profileModel.fetchProfileWithImages { result in
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                switch result {
                case .success(_):
                    print("✅ Profile and images loaded successfully")
                    self.isProfileLoaded = true
                    completion()
                    
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
        appController.coveFeed.fetchUserCoves { 
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                if let error = self.appController.coveFeed.errorMessage {
                    print("❌ User coves fetch failed: \(error)")
                    self.errorMessage = "Failed to fetch user coves: \(error)"
                } else {
                    print("✅ User coves fetched successfully")
                }
                
                // Mark as loaded regardless of success/failure
                self.isCovesLoaded = true
                
                // Start background prefetch for cove events (non-blocking)
                self.prefetchCoveEvents()
                
                // Navigate to home after everything is loaded
                self.navigateToHome()
            }
        }
    }
    
    private func navigateToHome() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        // Only navigate if all critical data is loaded (or failed to load)
        if isProfileLoaded && isCovesLoaded && isCalendarEventsLoaded && isUpcomingEventsLoaded {
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
                
                // Mark as logged in - this will switch to the main app flow
                appController.isLoggedIn = true
            }
        }
    }
    
    private func fetchCalendarEvents() {
        appController.calendarFeed.fetchCalendarEventsIfStale {
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                if let error = self.appController.calendarFeed.errorMessage {
                    print("❌ Calendar events fetch failed: \(error)")
                    self.errorMessage = "Failed to fetch calendar events: \(error)"
                } else {
                    print("✅ Calendar events fetched successfully")
                }
                
                // Mark as loaded regardless of success/failure
                self.isCalendarEventsLoaded = true
                
                // Navigate to home after everything is loaded
                self.navigateToHome()
            }
        }
    }
    
    private func fetchUpcomingEvents() {
        appController.upcomingFeed.fetchUpcomingEventsIfStale {
            DispatchQueue.main.async {
                // Check if view was cancelled
                guard !self.isCancelled else { return }
                
                if let error = self.appController.upcomingFeed.errorMessage {
                    print("❌ Upcoming events fetch failed: \(error)")
                    self.errorMessage = "Failed to fetch upcoming events: \(error)"
                } else {
                    print("✅ Upcoming events fetched successfully")
                }
                
                // Mark as loaded regardless of success/failure
                self.isUpcomingEventsLoaded = true
                
                // Navigate to home after everything is loaded
                self.navigateToHome()
            }
        }
    }
    
    private func prefetchCoveEvents() {
        // Get first 10 coves for prefetching
        let covesToPrefetch = Array(appController.coveFeed.userCoves.prefix(10))
        
        print("🔄 Starting background prefetch for \(covesToPrefetch.count) coves")
        
        // Start background prefetch for each cove (non-blocking)
        for cove in covesToPrefetch {
            let coveModel = appController.coveFeed.getOrCreateCoveModel(for: cove.id)
            // This will fetch cove details and first page of events
            coveModel.fetchCoveDetailsIfStale(coveId: cove.id)
        }
    }
}

#Preview {
    PluggingYouIn()
        .environmentObject(AppController.shared)
}
