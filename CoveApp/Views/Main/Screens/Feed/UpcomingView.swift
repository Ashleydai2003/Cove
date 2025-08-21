//
//  UpcomingView.swift
//  Cove
//

import SwiftUI
import FirebaseAuth

// MARK: - UpcomingView
struct UpcomingView: View {

    @EnvironmentObject var appController: AppController
    @ObservedObject private var upcomingFeed: UpcomingFeed
    @State private var topTabSelection: HomeTopTabs.Tab = .updates

    init() {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    CoveBannerView()

                    // Top tabs under header
                    HomeTopTabs(selected: $topTabSelection)

                    // Content switcher under tabs
                    Group {
                        switch topTabSelection {
                        case .updates:
                            ZStack {
                                ScrollView(showsIndicators: false) {
                                    VStack(spacing: 5) {
                                        contentView
                                        Spacer(minLength: 20)
                                    }
                                }
                                .refreshable {
                                    await withCheckedContinuation { continuation in
                                        upcomingFeed.refreshUpcomingEvents {
                                            continuation.resume()
                                        }
                                    }
                                }

                                // FloatingActionView - only show for verified/admin users
                                if isUserVerified {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            FloatingActionView(onEventCreated: {
                                                upcomingFeed.refreshUpcomingEvents()
                                            })
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 20)
                                        }
                                    }
                                }
                            }
                        case .calendar:
                            HomeCalendarView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: String.self) { eventId in
                // Find the event in our feed data to get the cover photo
                let upcomingEvent = appController.upcomingFeed.items.first { item in
                    switch item {
                    case .event(let event):
                        return event.id == eventId
                    case .post:
                        return false
                    }
                }
                
                // Extract the cover photo if it's an event
                let coverPhoto: CoverPhoto?
                switch upcomingEvent {
                case .event(let event):
                    coverPhoto = event.coveCoverPhoto
                case .post, .none:
                    coverPhoto = nil
                }
                
                return EventPostView(eventId: eventId, coveCoverPhoto: coverPhoto)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Wait for Firebase Auth token to be ready before fetching data
            waitForAuthTokenAndFetch()
        }
        .alert("error", isPresented: errorBinding) {
            Button("ok") { upcomingFeed.errorMessage = nil }
        } message: {
            Text(upcomingFeed.errorMessage ?? "")
        }
    }

    // MARK: - Computed Properties

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { upcomingFeed.errorMessage != nil },
            set: { if !$0 { upcomingFeed.errorMessage = nil } }
        )
    }

    /// Check if the current user is verified/admin
    private var isUserVerified: Bool {
        let verified = appController.profileModel.verified
        return verified
    }
    
    /// Waits for Firebase Auth token to be ready before fetching data
    private func waitForAuthTokenAndFetch() {
        guard let user = Auth.auth().currentUser else {
            Log.debug("UpcomingView: No authenticated user, skipping fetch")
            return
        }
        
        // Get the token to ensure it's valid
        user.getIDToken { token, error in
            DispatchQueue.main.async {
                if let error = error {
                    Log.debug("UpcomingView: Auth token error: \(error.localizedDescription)")
                    return
                }
                
                if token != nil {
                    Log.debug("UpcomingView: Auth token ready, fetching data")
                    upcomingFeed.fetchUpcomingEventsIfStale()
                } else {
                    Log.debug("UpcomingView: No auth token available")
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 16) {
            ForEach(Array(sortedItems.enumerated()), id: \.element.id) { idx, item in
                switch item {
                case .event(let event):
                    let calendarEvent = CalendarEvent(
                        id: event.id,
                        name: event.name,
                        description: event.description,
                        date: event.date,
                        location: event.location,
                        coveId: event.coveId,
                        coveName: event.coveName,
                        coveCoverPhoto: event.coveCoverPhoto,
                        hostId: event.hostId,
                        hostName: event.hostName,
                        rsvpStatus: event.rsvpStatus,
                        goingCount: event.goingCount,
                        createdAt: event.createdAt,
                        coverPhoto: event.coverPhoto
                    )
                    EventSummaryView(event: calendarEvent, type: .feed)
                        .padding(.horizontal, 20)
                        .onAppear {
                            loadMoreIfNeeded(at: idx)
                        }
                case .post(let post):
                    // Convert FeedPost to CovePost for PostSummaryView
                    let covePost = CovePost(
                        id: post.id,
                        content: post.content,
                        coveId: post.coveId,
                        coveName: post.coveName,
                        authorId: post.authorId,
                        authorName: post.authorName,
                        authorProfilePhotoUrl: post.authorProfilePhotoUrl,
                        isLiked: post.isLiked,
                        likeCount: post.likeCount,
                        createdAt: post.createdAt
                    )
                    // Provide a CoveModel so like toggles can be executed
                    let model = appController.coveFeed.getOrCreateCoveModel(for: covePost.coveId)
                    FeedPostSummaryView(post: covePost, viewModel: model)
                        .padding(.horizontal, 20)
                        .onAppear {
                            loadMoreIfNeeded(at: idx)
                        }
                }
            }

            if upcomingFeed.isLoading && !upcomingFeed.items.isEmpty {
                LoadingIndicatorView()
            }
        }
    }

    // Sort items so that:
    // - Upcoming events (date >= now) appear first, ascending by date
    // - Posts appear next, descending by createdAt
    // - Past events (date < now) appear last, descending by date
    private var sortedItems: [FeedItem] {
        let now = Date()
        var upcomingEvents: [(Date, FeedEvent)] = []
        var posts: [(Date, FeedPost)] = []
        var pastEvents: [(Date, FeedEvent)] = []
        for item in upcomingFeed.items {
            switch item {
            case .event(let ev):
                let date = ISO8601DateFormatter().date(from: ev.date) ?? Date.distantPast
                if date >= now {
                    upcomingEvents.append((date, ev))
                } else {
                    pastEvents.append((date, ev))
                }
            case .post(let p):
                let created = ISO8601DateFormatter().date(from: p.createdAt) ?? Date.distantPast
                posts.append((created, p))
            }
        }
        upcomingEvents.sort { $0.0 < $1.0 }
        posts.sort { $0.0 > $1.0 }
        pastEvents.sort { $0.0 > $1.0 }
        return upcomingEvents.map { .event($0.1) } + posts.map { .post($0.1) } + pastEvents.map { .event($0.1) }
    }

    private func loadMoreIfNeeded(at index: Int) {
        if index == upcomingFeed.items.count - 1 {
            upcomingFeed.loadMoreEventsIfNeeded()
        }
    }
}

// MARK: - Home Top Tabs
private struct HomeTopTabs: View {
    @Binding var selected: Tab
    @Namespace private var underlineNamespace

    enum Tab { case updates, calendar }

    var body: some View {
        HStack {
            // Updates tab (default)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) { selected = .updates }
            }) {
                VStack(spacing: 4) {
                    Text("updates")
                        .font(.LibreBodoni(size: 14))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .updates {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "tabUnderline", in: underlineNamespace)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 2)
                }
            }

            Spacer()

            // Calendar tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) { selected = .calendar }
            }) {
                VStack(spacing: 4) {
                    Text("calendar")
                        .font(.LibreBodoni(size: 14))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .calendar {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "tabUnderline", in: underlineNamespace)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Colors.primaryDark)
            Text("loading your events...")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Error State
private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(Colors.primaryDark)

            Text("no upcoming events or posts – create something epic!")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Feed Items List
private struct FeedItemsListView: View {
    @ObservedObject private var upcomingFeed: UpcomingFeed

    init() {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(upcomingFeed.items.enumerated()), id: \.element.id) { idx, item in
                switch item {
                case .event(let event):
                    // Convert FeedEvent to CalendarEvent for EventSummaryView
                    let calendarEvent = CalendarEvent(
                        id: event.id,
                        name: event.name,
                        description: event.description,
                        date: event.date,
                        location: event.location,
                        coveId: event.coveId,
                        coveName: event.coveName,
                        coveCoverPhoto: event.coveCoverPhoto,
                        hostId: event.hostId,
                        hostName: event.hostName,
                        rsvpStatus: event.rsvpStatus,
                        goingCount: event.goingCount,
                        createdAt: event.createdAt,
                        coverPhoto: event.coverPhoto
                    )
                    EventSummaryView(event: calendarEvent, type: .feed)
                        .padding(.horizontal, 20)
                        .onAppear {
                            loadMoreIfNeeded(at: idx)
                        }
                case .post(let post):
                    // Convert FeedPost to CovePost for PostSummaryView
                    let covePost = CovePost(
                        id: post.id,
                        content: post.content,
                        coveId: post.coveId,
                        coveName: post.coveName,
                        authorId: post.authorId,
                        authorName: post.authorName,
                        authorProfilePhotoUrl: post.authorProfilePhotoUrl,
                        isLiked: post.isLiked,
                        likeCount: post.likeCount,
                        createdAt: post.createdAt
                    )
                    FeedPostSummaryView(post: covePost)
                    .padding(.horizontal, 20)
                    .onAppear {
                        loadMoreIfNeeded(at: idx)
                        }
                    }
            }

            if upcomingFeed.isLoading && !upcomingFeed.items.isEmpty {
                LoadingIndicatorView()
            }
        }
    }

    private func loadMoreIfNeeded(at index: Int) {
        if index == upcomingFeed.items.count - 1 {
            upcomingFeed.loadMoreEventsIfNeeded()
        }
    }
}

// MARK: - Loading Indicator
private struct LoadingIndicatorView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Colors.primaryDark)
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Preview
struct UpcomingView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingView()
            .environmentObject(AppController.shared)
    }
}
