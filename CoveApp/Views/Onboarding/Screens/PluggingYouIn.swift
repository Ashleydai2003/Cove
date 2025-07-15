import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct PluggingYouIn: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController

    /// Static list of preset fun loading messages. The view will cycle through these instead of reflecting real-time progress.
    private static let presetMessages: [String] = [
        "finding good vibes…",
        "loading your profile…",
        "syncing your calendar…",
        "checking for the next big event…",
        "connecting to server…",
        "dusting off invites…",
        "bringing your friends over…",
        "checking inbox…",
        "almost there…",
        "good vibes loading…"
    ]

    /// Index into `presetMessages` currently displayed
    @State private var messageIndex = 0
    /// Timer for cycling through preset messages
    @State private var messageTimer: Timer?
    @State private var rotation: Double = 0
    @State private var animationTimer: Timer?
    @State private var statusMessage: String = PluggingYouIn.presetMessages[0]
    @State private var isLoading = true
    @State private var profileImagesPrefetched = false
    
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
                        loadUserData()
                    }
                    .onDisappear {
                        stopAnimation()
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

        // Start the message-cycling timer (every ~2.5 seconds)
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            // Advance to next preset message with a gentle fade
            withAnimation(.easeInOut(duration: 1)) {
                messageIndex = (messageIndex + 1) % PluggingYouIn.presetMessages.count
                statusMessage = PluggingYouIn.presetMessages[messageIndex]
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil

        messageTimer?.invalidate()
        messageTimer = nil
    }
    
    private func loadUserData() {
        Log.debug("🔌 PluggingYouIn: Starting data load")
        
        // Initialize AppController data
        appController.initializeAfterLogin()
        
        // Start all data fetches in parallel
        fetchUserProfile()
        fetchUserCoves()
        fetchCalendarEvents()
        fetchUpcomingEvents()
        fetchInvites()
        fetchFriendRequests()
        fetchMutuals()
        fetchFriends()
        
        // Set a reasonable timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if isLoading && !profileImagesPrefetched {
                Log.debug("🔌 PluggingYouIn: Loading timeout reached without profile images, proceeding to main app")
                completeLoading()
            }
        }
    }
    
    private func completeLoading() {
        guard isLoading else { return }
        isLoading = false
        
        // Stop the animation
        stopAnimation()
        
        // Complete the current rotation smoothly
        withAnimation(.easeInOut(duration: 0.3)) {
            rotation = Double(Int(rotation / 180) + 1) * 180.0 // Complete to next 180-degree increment
        }
        
        // Navigate to main app after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Ensure profile images continue loading even after timeout
            if !self.profileImagesPrefetched {
                Log.debug("🖼️ Profile images not yet prefetched, continuing to load in background")
                self.prefetchProfileImages()
            }
            
            appController.isLoggedIn = true
        }
    }
    
    private func fetchUserProfile() {
        appController.profileModel.fetchProfileWithImages { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    Log.debug("✅ Profile and images loaded successfully")
                    // Prefetch profile images after successful load
                    self.prefetchProfileImages()
                case .failure(let error):
                    Log.debug("❌ Profile fetch failed: \(error.localizedDescription)")
                    // Still try to prefetch profile images even if fetch failed
                    // (in case there are cached images or partial data)
                    self.prefetchProfileImages()
                }
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchUserCoves() {
        appController.coveFeed.fetchUserCoves { 
            DispatchQueue.main.async {
                if let error = self.appController.coveFeed.errorMessage {
                    Log.debug("❌ User coves fetch failed: \(error)")
                } else {
                    Log.debug("✅ User coves fetched successfully")
                    // Prefetch cove cover images after successful load
                    self.prefetchCoveCoverImages()
                    // Start background prefetching of cove events
                    self.prefetchCoveEvents()
                }
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchCalendarEvents() {
        appController.calendarFeed.fetchCalendarEventsIfStale {
            DispatchQueue.main.async {
                if let error = self.appController.calendarFeed.errorMessage {
                    Log.debug("❌ Calendar events fetch failed: \(error)")
                } else {
                    Log.debug("✅ Calendar events fetched successfully")
                }
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchUpcomingEvents() {
        appController.upcomingFeed.fetchUpcomingEventsIfStale {
            DispatchQueue.main.async {
                if let error = self.appController.upcomingFeed.errorMessage {
                    Log.debug("❌ Upcoming events fetch failed: \(error)")
                } else {
                    Log.debug("✅ Upcoming events fetched successfully")
                    // Prefetch upcoming event cover photos
                    self.prefetchUpcomingEventImages()
                }
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchInvites() {
        Log.debug("📮 PluggingYouIn: Starting fetchInvites...")
        // Initialize inbox through AppController method
        appController.initializeAfterLogin()
        
        // Use a simple timeout instead of polling
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            DispatchQueue.main.async {
                Log.debug("📮 PluggingYouIn: Inbox loading timeout completed")
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchFriendRequests() {
        Log.debug("📬 PluggingYouIn: Starting fetchFriendRequests...")
        appController.requestsViewModel.loadNextPage()
        
        // Use a simple timeout instead of polling
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            DispatchQueue.main.async {
                Log.debug("📬 PluggingYouIn: Friend requests loading timeout completed")
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchMutuals() {
        Log.debug("🔗 PluggingYouIn: Starting fetchMutuals...")
        appController.mutualsViewModel.loadNextPage()
        
        // Use a simple timeout instead of polling
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            DispatchQueue.main.async {
                Log.debug("🔗 PluggingYouIn: Mutuals loading timeout completed")
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func fetchFriends() {
        Log.debug("👥 PluggingYouIn: Starting fetchFriends...")
        appController.friendsViewModel.loadNextPage()
        
        // Use a simple timeout instead of polling
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            DispatchQueue.main.async {
                Log.debug("👥 PluggingYouIn: Friends loading timeout completed")
                self.checkIfAllDataLoaded()
            }
        }
    }
    
    private func checkIfAllDataLoaded() {
        // For now, we'll rely on the timeout to complete loading
        // This prevents the screen from getting stuck if some data fails to load
        // The timeout ensures users don't wait forever
    }
    
    // MARK: - Image Prefetching
    
    /// Prefetch profile images so they appear immediately on the home screen
    private func prefetchProfileImages() {
        let profileImages = appController.profileModel.photos
        let urls = profileImages.compactMap { $0.url.absoluteString }
        
        Log.debug("🖼️ Profile prefetching: Found \(profileImages.count) profile images, \(urls.count) valid URLs")
        
        if !urls.isEmpty {
            Log.debug("🖼️ Prefetching \(urls.count) profile images: \(urls)")
            ImagePrefetcherUtil.prefetch(urlStrings: urls) {
                Log.debug("🖼️ Profile images prefetching completed")
                DispatchQueue.main.async {
                    self.profileImagesPrefetched = true
                    self.checkIfReadyToComplete()
                }
            }
        } else {
            Log.debug("🖼️ No profile images to prefetch - photos array is empty or has no valid URLs")
            // Mark as completed even if no images to prefetch
            DispatchQueue.main.async {
                self.profileImagesPrefetched = true
                self.checkIfReadyToComplete()
            }
        }
    }
    
    private func checkIfReadyToComplete() {
        // Wait for profile images to be prefetched before completing
        if profileImagesPrefetched && isLoading {
            Log.debug("🖼️ Profile images prefetched, completing loading")
            completeLoading()
        }
    }
    
    /// Prefetch the first 5 cove cover images so that home feed looks populated immediately
    private func prefetchCoveCoverImages() {
        let urls = appController.coveFeed.userCoves.prefix(6).compactMap { $0.coverPhoto?.url }
        
        if !urls.isEmpty {
            Log.debug("🖼️ Prefetching \(urls.count) cove cover images")
            ImagePrefetcherUtil.prefetch(urlStrings: urls)
        }
    }
    
    /// Prefetch cove events in the background for faster navigation
    private func prefetchCoveEvents() {
        // Get first 6 coves for prefetching (just enough for a nice landing state)
        let covesToPrefetch = Array(appController.coveFeed.userCoves.prefix(6))
        
        if !covesToPrefetch.isEmpty {
            Log.debug("🔄 Starting background prefetch for \(covesToPrefetch.count) coves")
            
            // Start background prefetch for each cove (non-blocking)
            for cove in covesToPrefetch {
                let coveModel = appController.coveFeed.getOrCreateCoveModel(for: cove.id)
                // This will fetch cove details and first page of events
                coveModel.fetchCoveDetailsIfStale(coveId: cove.id)
            }
        }
    }
    
    /// Prefetch upcoming event cover photos for the home feed
    private func prefetchUpcomingEventImages() {
        let urls = appController.upcomingFeed.events.prefix(5).compactMap { $0.coveCoverPhoto?.url }
        
        if !urls.isEmpty {
            Log.debug("🖼️ Prefetching \(urls.count) upcoming event cover images")
            ImagePrefetcherUtil.prefetch(urlStrings: urls)
        }
    }
}

#Preview {
    PluggingYouIn()
        .environmentObject(AppController.shared)
}

