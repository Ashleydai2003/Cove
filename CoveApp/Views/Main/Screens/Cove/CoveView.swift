//
//  CoveView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI
import Kingfisher

/// CoveView: Displays the feed for a specific cove, including cove details and events.
struct CoveView: View {
    enum Tab: Int, CaseIterable {
        case events, posts, members
        var title: String {
            switch self {
            case .events: return "events"
            case .posts: return "posts"
            case .members: return "members"
            }
        }
    }

    @ObservedObject var viewModel: CoveModel
    let coveId: String
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .events
    @GestureState private var isHorizontalSwiping: Bool = false
    @State private var headerOpacity: CGFloat = 1.0

    // TODO: admin can update cove cover photo

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.events.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Colors.primaryDark)
                    Text("loading your cove...")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let cove = viewModel.cove {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            // Top anchor for programmatic scrolling
                            Color.clear.frame(height: 0).id("topAnchor")

                            // Fading header
                            CoveInfoHeaderView(
                                cove: cove,
                                onBackTapped: { dismiss() },
                                isRefreshing: viewModel.isRefreshingCoveDetails,
                                onRefresh: {
                                    await withCheckedContinuation { continuation in
                                        viewModel.refreshCoveDetails()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            continuation.resume()
                                        }
                                    }
                                }
                            )
                            .opacity(headerOpacity)
                            .animation(.easeInOut(duration: 0.18), value: headerOpacity)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: CoveHeaderOffsetPreferenceKey.self,
                                            value: CoveHeaderOffset(
                                                height: geo.size.height,
                                                minY: geo.frame(in: .named("coveScroll")).minY
                                            )
                                        )
                                }
                            )

                            // Pinned tabs
                            Section(
                                header:
                                    ZStack(alignment: .bottom) {
                                        Colors.background.ignoresSafeArea(edges: .top)
                                        CoveDetailTabs(selected: Binding(
                                            get: { selectedTab },
                                            set: { selectedTab = $0 }
                                        ))
                                        .padding(.horizontal, 30)
                                        .padding(.top, 6)
                                    }
                                    .zIndex(1000)
                            ) {
                                Group {
                                    switch selectedTab {
                                    case .events:
                                        eventsContent
                                            .padding(.horizontal, 24)
                                    case .posts:
                                        postsContent
                                            .padding(.horizontal, 24)
                                    case .members:
                                        membersContent
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "coveScroll")
                    .onPreferenceChange(CoveHeaderOffsetPreferenceKey.self) { data in
                        let progress = min(max(-data.minY / max(data.height, 1), 0), 1)
                        headerOpacity = 1 - progress
                    }
                    .refreshable {
                        await withCheckedContinuation { continuation in
                            switch selectedTab {
                            case .events:
                                viewModel.refreshEvents()
                            case .posts:
                                viewModel.refreshPosts()
                            case .members:
                                viewModel.refreshMembers()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                continuation.resume()
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
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
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    switch selectedTab {
                                    case .events: selectedTab = .posts
                                    case .posts: selectedTab = .members
                                    case .members: break
                                    }
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    switch selectedTab {
                                    case .events: break
                                    case .posts: selectedTab = .events
                                    case .members: selectedTab = .posts
                                    }
                                }
                            }
                        }
                )
                .overlay(
                    Color.clear
                        .ignoresSafeArea()
                        .allowsHitTesting(isHorizontalSwiping)
                )
                .background(Colors.background)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text(error)
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionView(coveId: coveId, onEventCreated: {
                        // Refresh both events and posts when something is created
                        viewModel.refreshEvents()
                        viewModel.refreshPosts()
                    })
                        .padding(.trailing, 24)
                        .padding(.bottom, 30)
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchCoveDetailsIfStale(coveId: coveId)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .members {
                // Fetch members when members tab is selected
                viewModel.fetchCoveMembers(coveId: coveId)
            } else if newTab == .posts {
                // Fetch posts when posts tab is selected
                viewModel.fetchPosts(coveId: coveId)
            }
        }
        .alert("error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ok") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Cove Detail Tabs
private struct CoveDetailTabs: View {
    @Binding var selected: CoveView.Tab
    @Namespace private var underlineNamespace

    var body: some View {
        HStack {
            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .events } }) {
                VStack(spacing: 6) {
                    Text("events")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .events {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }

            Spacer()

            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .posts } }) {
                VStack(spacing: 6) {
                    Text("posts")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .posts {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }

            Spacer()

            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .members } }) {
                VStack(spacing: 6) {
                    Text("members")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .members {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }
        }
    }
}

// MARK: - Header Fade Tracking
private struct CoveHeaderOffset: Equatable {
    let height: CGFloat
    let minY: CGFloat
}

private struct CoveHeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CoveHeaderOffset = CoveHeaderOffset(height: 1, minY: 0)
    static func reduce(value: inout CoveHeaderOffset, nextValue: () -> CoveHeaderOffset) {
        value = nextValue()
    }
}

// MARK: - Inline Tab Contents
private extension CoveView {
    var eventsContent: some View {
        VStack(spacing: 5) {
            ForEach(sortedEvents, id: \.id) { event in
                EventSummaryView(event: event, type: .cove, disableNavigation: isHorizontalSwiping)
                    .onAppear {
                        DispatchQueue.main.async {
                            viewModel.loadMoreEventsIfNeeded(currentEvent: event)
                        }
                    }
            }
            if viewModel.isRefreshingEvents || (viewModel.isLoading && !viewModel.events.isEmpty) {
                HStack { Spacer(); ProgressView().tint(Colors.primaryDark); Spacer() }
                    .padding(.vertical, 16)
            }
            if viewModel.events.isEmpty && !viewModel.isLoading && !viewModel.isRefreshingEvents {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(Colors.primaryDark)
                    Text("no events yet – be the first to host!")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            }
            Spacer(minLength: 20)
        }
    }

    var postsContent: some View {
        VStack(spacing: 5) {
            ForEach(viewModel.posts, id: \.id) { post in
                PostSummaryView(post: post, type: .cove, viewModel: viewModel)
                    .onAppear {
                        DispatchQueue.main.async {
                            viewModel.loadMorePostsIfNeeded(currentPost: post)
                        }
                    }
            }
            if viewModel.isRefreshingPosts || (viewModel.isLoading && !viewModel.posts.isEmpty) {
                HStack { Spacer(); ProgressView().tint(Colors.primaryDark); Spacer() }
                    .padding(.vertical, 16)
            }
            if viewModel.posts.isEmpty && !viewModel.isLoading && !viewModel.isRefreshingPosts {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(Colors.primaryDark)
                    Text("no posts yet – be the first to share!")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            }
            Spacer(minLength: 20)
        }
    }

    var membersContent: some View {
        VStack(spacing: 16) {
            if let cove = viewModel.cove {
                HStack {
                    Text("\(cove.stats.memberCount) members")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniBold(size: 18))
                    Spacer()
                    if viewModel.isCurrentUserAdmin {
                        Button(action: { /* open invites elsewhere in full view */ }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Colors.primaryDark)
                        }
                    }
                }
                .padding(.top, 16)
            }

            LazyVStack(spacing: 12) {
                ForEach(viewModel.members) { member in
                    NavigationLink(destination: FriendProfileView(userId: member.id, initialPhotoUrl: member.profilePhotoUrl)) {
                        MemberRowView(
                            member: member,
                            currentUserId: appController.profileModel.userId,
                            friendsViewModel: appController.friendsViewModel,
                            mutualsViewModel: appController.mutualsViewModel,
                            requestsViewModel: appController.requestsViewModel,
                            onMessage: { }
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isHorizontalSwiping)
                    .onAppear { viewModel.loadMoreMembersIfNeeded(currentMember: member) }
                }
            }

            if viewModel.isRefreshingMembers {
                HStack { Spacer(); ProgressView().tint(Colors.primaryDark); Spacer() }
                    .padding(.vertical, 16)
            }

            if viewModel.members.isEmpty && !viewModel.isRefreshingMembers {
                VStack(spacing: 16) {
                    Image(systemName: "person.3").font(.system(size: 40)).foregroundColor(Colors.primaryDark)
                    Text("no members found")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            }
            Spacer(minLength: 20)
        }
    }

    var sortedEvents: [CalendarEvent] {
        let now = Date()
        var upcoming: [(Date, CalendarEvent)] = []
        var past: [(Date, CalendarEvent)] = []
        for ev in viewModel.events {
            let d = ev.eventDate
            if d >= now { upcoming.append((d, ev)) } else { past.append((d, ev)) }
        }
        upcoming.sort { $0.0 < $1.0 }
        past.sort { $0.0 > $1.0 }
        return upcoming.map { $0.1 } + past.map { $0.1 }
    }
}

#Preview {
    CoveView(viewModel: CoveModel(), coveId: "1")
}
