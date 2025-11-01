//
//  UpcomingView.swift
//  Cove
//

import SwiftUI
import UIKit
import FirebaseAuth

// MARK: - UpcomingView
struct UpcomingView: View {

    @EnvironmentObject var appController: AppController
    @ObservedObject private var upcomingFeed: UpcomingFeed
    @State private var topTabSelection: HomeTopTabs.Tab = .updates
    @State private var headerOpacity: CGFloat = 1.0
    @GestureState private var isHorizontalSwiping: Bool = false

    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath>) {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
        self._navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Colors.background.ignoresSafeArea()

                // Scrollable content with pinned tabs and fading header
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            // Top anchor for programmatic scrolling
                            Color.clear.frame(height: 0).id("topAnchor")

                            // Fading header shown across tabs; fades only when on Discovery
                            CoveBannerView()
                                .background(Colors.background)
                                .opacity(headerOpacity)
                                .animation(.easeInOut(duration: 0.18), value: headerOpacity)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: HeaderOffsetPreferenceKey.self,
                                                value: HeaderOffset(
                                                    height: geo.size.height,
                                                    minY: geo.frame(in: .named("upcomingScroll")).minY
                                                )
                                            )
                                    }
                                )

                            // Pinned tabs
                            Section(
                                header:
                                    ZStack(alignment: .bottom) {
                                        Colors.background.ignoresSafeArea(edges: .top)
                                        HomeTopTabs(selected: $topTabSelection)
                                    }
                                    .zIndex(1000)
                            ) {
                                Group {
                                    if topTabSelection == .updates {
                                        VStack(spacing: 5) {
                                            contentView
                                            Spacer(minLength: 20)
                                        }
                                        .zIndex(0)
                                    } else {
                                        CalendarView(navigationPath: $navigationPath)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: topTabSelection) { oldValue, newValue in
                        if newValue == .discover {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                proxy.scrollTo("topAnchor", anchor: .top)
                            }
                        }
                    }
                }
                .coordinateSpace(name: "upcomingScroll")
                .onPreferenceChange(HeaderOffsetPreferenceKey.self) { data in
                    guard topTabSelection == .updates else { return }
                    let progress = min(max(-data.minY / max(data.height, 1), 0), 1)
                    headerOpacity = 1 - progress
                }
                .refreshable {
                    await withCheckedContinuation { continuation in
                        if topTabSelection == .updates {
                            upcomingFeed.refreshUpcomingEvents {
                                continuation.resume()
                            }
                        } else {
                            continuation.resume()
                        }
                    }
                }

                // Opaque top-safe-area overlay to prevent content peeking during bounce
                GeometryReader { proxy in
                    Colors.background
                        .frame(height: proxy.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .allowsHitTesting(false)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 16)
                    .updating($isHorizontalSwiping) { value, state, _ in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        if abs(dx) > abs(dy) && abs(dx) > 10 { state = true }
                    }
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > abs(dy), abs(dx) > 30 else { return }
                        if dx < 0 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.22)) { topTabSelection = .discover }
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.22)) { topTabSelection = .updates }
                        }
                    }
            )
            .overlay(
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(isHorizontalSwiping)
            )
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
        if sortedItems.isEmpty {
            // Empty state for discover tab
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.primaryDark)
                
                Text("no updates yet")
                    .font(.LibreBodoniBold(size: 20))
                    .foregroundColor(Colors.primaryDark)
                
                Text("when events and posts are shared, they'll appear here")
                    .font(.LibreBodoni(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: UIScreen.main.bounds.height - 200)
        } else {
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
                        memberCap: event.memberCap,
                        ticketPrice: event.ticketPrice,
                        coveId: event.coveId ?? "",
                        coveName: event.coveName,
                        coveCoverPhoto: event.coveCoverPhoto,
                        hostId: event.hostId ?? "",
                        hostName: event.hostName,
                        rsvpStatus: event.rsvpStatus,
                        goingCount: event.goingCount,
                        pendingCount: nil,
                        createdAt: event.createdAt,
                        coverPhoto: event.coverPhoto
                    )
                    EventSummaryView(event: calendarEvent, type: .feed, disableNavigation: isHorizontalSwiping)
                        .padding(.horizontal, 24)
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
                        .padding(.horizontal, 24)
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
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging: Bool = false

    enum Tab { case updates, discover }

    var body: some View {
        HStack {
            // Discovery tab (default)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.22)) { selected = .updates }
            }) {
                VStack(spacing: 6) {
                    Text("discovery 🔎")
                        .font(.LibreBodoni(size: 16))
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
                    .frame(height: 1)
                    .opacity(isDragging ? 0 : 1)
                }
            }
            .anchorPreference(key: HomeTabBoundsKey.self, value: .bounds) { ["discovery": $0] }

            Spacer()

            // Calendar tab
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.22)) { selected = .discover }
            }) {
                VStack(spacing: 6) {
                    Text("calendar 📅")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .discover {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "tabUnderline", in: underlineNamespace)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 1)
                    .opacity(isDragging ? 0 : 1)
                }
            }
            .anchorPreference(key: HomeTabBoundsKey.self, value: .bounds) { ["calendar": $0] }
        }
        .padding(.horizontal, 30)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    isDragging = true
                    dragTranslation = value.translation.width
                }
                .onEnded { value in
                    isDragging = false
                    let endTranslation = value.translation.width
                    if endTranslation < -30 {
                        withAnimation(.easeInOut(duration: 0.22)) { selected = .discover }
                    } else if endTranslation > 30 {
                        withAnimation(.easeInOut(duration: 0.22)) { selected = .updates }
                    }
                    dragTranslation = 0
                }
        )
        .overlayPreferenceValue(HomeTabBoundsKey.self) { prefs in
            GeometryReader { proxy in
                if let leftAnchor = prefs["discovery"], let rightAnchor = prefs["calendar"] {
                    let leftFrame = proxy[leftAnchor]
                    let rightFrame = proxy[rightAnchor]
                    let leftCenterX = leftFrame.midX
                    let rightCenterX = rightFrame.midX
                    let distance = rightCenterX - leftCenterX
                    let base: CGFloat = (selected == .updates) ? 0 : 1
                    let dragProgress: CGFloat = isDragging && distance != 0 ? (-dragTranslation / distance) : 0
                    let t = min(max(base + dragProgress, 0), 1)
                    let width = leftFrame.width + (rightFrame.width - leftFrame.width) * t
                    let centerX = leftCenterX + distance * t
                    let underlineY = max(leftFrame.maxY, rightFrame.maxY) + 1

                    Capsule()
                        .fill(Colors.primaryDark)
                        .frame(width: width, height: 1)
                        .position(x: centerX, y: underlineY)
                        .animation(.easeInOut(duration: 0.12), value: selected)
                        .opacity(isDragging ? 1 : 0)
                }
            }
        }
    }
}

// Preference key for capturing tab bounds in Home tabs
private struct HomeTabBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// Preference for tracking header offset to compute fade
private struct HeaderOffset: Equatable {
    let height: CGFloat
    let minY: CGFloat
}

private struct HeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: HeaderOffset = HeaderOffset(height: 1, minY: 0)
    static func reduce(value: inout HeaderOffset, nextValue: () -> HeaderOffset) {
        value = nextValue()
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
                        memberCap: event.memberCap,
                        ticketPrice: event.ticketPrice,
                        coveId: event.coveId ?? "",
                        coveName: event.coveName,
                        coveCoverPhoto: event.coveCoverPhoto,
                        hostId: event.hostId ?? "",
                        hostName: event.hostName,
                        rsvpStatus: event.rsvpStatus,
                        goingCount: event.goingCount,
                        pendingCount: nil,
                        createdAt: event.createdAt,
                        coverPhoto: event.coverPhoto
                    )
                    EventSummaryView(event: calendarEvent, type: .feed)
                        .padding(.horizontal, 24)
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
                    .padding(.horizontal, 24)
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
        UpcomingView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AppController.shared)
    }
}

