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
    @State private var isInboxLoaded = false
    @State private var isFriendRequestsLoaded = false
    @State private var isMutualsLoaded = false
    @State private var isFriendsLoaded = false
    @State private var areCoverImagesPrefetched = false
    @State private var animationTimer: Timer?
    @State private var statusMessage: String = "plugging you in…"
    @State private var isCancelled = false
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
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
                
                // Static tagline
                Text("plugging you in…")
                    .font(.LibreBodoni(size: 35))
                    .foregroundColor(Colors.primaryDark)

                // Smaller status message shown under the tagline
                if statusMessage != "plugging you in…" {
                    Text(statusMessage)
                        .font(.LibreBodoni(size: 18))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                }
                
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
        
        print("🔌 PluggingYouIn: Starting plugInUser - verified = \(appController.profileModel.verified)")
        
        // Check if user is in onboarding mode (this should be set during login)
        if appController.profileModel.onboarding {
            print("📱 User is in onboarding mode, completing onboarding...")
            statusMessage = "completing onboarding…"
            completeOnboarding()
        } else {
            print("📱 User is not in onboarding mode, proceeding with normal flow...")
            fetchUserProfile {
                print("🔌 PluggingYouIn: After profile fetch - verified = \(self.appController.profileModel.verified)")
                self.fetchUserCoves()
                self.fetchCalendarEvents()
                self.fetchUpcomingEvents()
                self.fetchInvites()
                self.fetchFriendRequests()
                self.fetchMutuals()
                self.fetchFriends()
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
                        self.fetchInvites()
                        self.fetchFriendRequests()
                        self.fetchMutuals()
                        self.fetchFriends()
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
                
                // Prefetch events and cove cover images
                self.statusMessage = "loading your events…"
                self.prefetchCoveEvents()
                self.prefetchCoveCoverImages {
                    self.areCoverImagesPrefetched = true
                    self.navigateToHome()
                }
            }
        }
    }
    
    private func navigateToHome() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        // Only navigate if all critical data is loaded (or failed to load)
        if isProfileLoaded && isCovesLoaded && isCalendarEventsLoaded && isUpcomingEventsLoaded && isInboxLoaded && isFriendRequestsLoaded && isMutualsLoaded && isFriendsLoaded && areCoverImagesPrefetched {
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
        statusMessage = "syncing calendar…"
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
        statusMessage = "finding upcoming events…"
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
    
    private func fetchInvites() {
        print("📮 PluggingYouIn: Starting fetchInvites...")
        // Initialize inbox through AppController method
        statusMessage = "checking inbox…"
        appController.initializeAfterLogin()
        
        // Monitor the inbox loading state properly
        let checkInboxCompletion = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkInboxLoadingStatus()
            }
        }
        
        checkInboxCompletion()
    }
    
    private func fetchFriendRequests() {
        print("📬 PluggingYouIn: Starting fetchFriendRequests...")
        statusMessage = "checking friend requests…"
        appController.requestsViewModel.loadNextPage()
        
        // Monitor the friend requests loading state
        let checkRequestsCompletion = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkFriendRequestsLoadingStatus()
            }
        }
        
        checkRequestsCompletion()
    }
    
    private func fetchMutuals() {
        print("🔗 PluggingYouIn: Starting fetchMutuals...")
        statusMessage = "looking for friends…"
        appController.mutualsViewModel.loadNextPage()
        
        // Monitor the mutuals loading state
        let checkMutualsCompletion = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkMutualsLoadingStatus()
            }
        }
        
        checkMutualsCompletion()
    }
    
    private func fetchFriends() {
        print("👥 PluggingYouIn: Starting fetchFriends...")
        statusMessage = "bringing your friends over…"
        appController.friendsViewModel.loadNextPage()
        
        // Monitor the friends loading state
        let checkFriendsCompletion = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkFriendsLoadingStatus()
            }
        }
        
        checkFriendsCompletion()
    }
    
    private func checkInboxLoadingStatus() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        if !appController.inboxViewModel.isLoading {
            // Inbox loading is complete (either success or failure)
            print("📮 PluggingYouIn: Inbox loading completed")
            isInboxLoaded = true
            navigateToHome()
        } else {
            // Still loading, check again in 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkInboxLoadingStatus()
            }
        }
    }
    
    private func checkFriendRequestsLoadingStatus() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        if !appController.requestsViewModel.isLoading {
            // Friend requests loading is complete (either success or failure)
            print("📬 PluggingYouIn: Friend requests loading completed")
            isFriendRequestsLoaded = true
            navigateToHome()
        } else {
            // Still loading, check again in 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkFriendRequestsLoadingStatus()
            }
        }
    }
    
    private func checkMutualsLoadingStatus() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        if !appController.mutualsViewModel.isLoading {
            // Mutuals loading is complete (either success or failure)
            print("🔗 PluggingYouIn: Mutuals loading completed")
            isMutualsLoaded = true
            navigateToHome()
        } else {
            // Still loading, check again in 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkMutualsLoadingStatus()
            }
        }
    }
    
    private func checkFriendsLoadingStatus() {
        // Check if view was cancelled
        guard !isCancelled else { return }
        
        if !appController.friendsViewModel.isLoading {
            // Friends loading is complete (either success or failure)
            print("👥 PluggingYouIn: Friends loading completed")
            isFriendsLoaded = true
            navigateToHome()
        } else {
            // Still loading, check again in 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkFriendsLoadingStatus()
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

    /// Prefetch the first 10 cove cover images so that home feed looks populated immediately
    private func prefetchCoveCoverImages(completion: @escaping () -> Void) {
        let urls = appController.coveFeed.userCoves.prefix(10).compactMap { $0.coverPhoto?.url }
        ImagePrefetcherUtil.prefetch(urlStrings: urls, completion: completion)
    }
}

#Preview {
    PluggingYouIn()
        .environmentObject(AppController.shared)
}
