//
//  UpcomingView.swift
//  Cove
//

import SwiftUI

// MARK: - UpcomingView
struct UpcomingView: View {

    @EnvironmentObject var appController: AppController
    @ObservedObject private var upcomingFeed: UpcomingFeed

    init() {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
    }

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            upcomingFeed.fetchUpcomingEventsIfStale()
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

    @ViewBuilder
    private var contentView: some View {
        if upcomingFeed.isLoading && upcomingFeed.items.isEmpty {
            LoadingStateView()
        } else if let error = upcomingFeed.errorMessage {
            ErrorStateView(message: error)
        } else if upcomingFeed.items.isEmpty {
            EmptyStateView()
        } else {
            FeedItemsListView()
        }
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
