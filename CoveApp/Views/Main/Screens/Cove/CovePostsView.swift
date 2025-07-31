//
//  CovePostsView.swift
//  Cove
//
//  Created by Ashley Dai on 7/1/25.
//

import SwiftUI
import Kingfisher

/// CovePostsView: Reusable component for displaying cove posts list
/// - Shows scrollable list of posts with pull-to-refresh
/// - Handles pagination and loading states
struct CovePostsView: View {
    @ObservedObject var viewModel: CoveModel
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(viewModel.posts, id: \.id) { post in
                    PostSummaryView(post: post, type: .cove, viewModel: viewModel)
                        .onAppear {
                            DispatchQueue.main.async {
                                viewModel.loadMorePostsIfNeeded(currentPost: post)
                            }
                        }
                }

                // Cute empty state
                if viewModel.posts.isEmpty && !viewModel.isLoading && !viewModel.isRefreshingPosts {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(Colors.primaryDark)
                        Text("no posts yet – be the first to share!")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }

                // Show loading indicator only for posts
                if viewModel.isRefreshingPosts || (viewModel.isLoading && !viewModel.posts.isEmpty) {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

/// PostView: Displays a single post in the feed, including content and details.
struct PostView: View {
    let post: CovePost

    var body: some View {
        NavigationLink(value: post.id) {
            VStack(alignment: .leading) {
                HStack {
                    HStack(spacing: 5) {
                        Text("@\(post.authorName.lowercased())")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                    }

                    Spacer()

                    Text(timeAgo(post.createdAt))
                        .foregroundStyle(Color.black)
                        .font(.LibreBodoniSemiBold(size: 12))
                }

                Text(post.content)
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoniSemiBold(size: 12))
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 10)
        }
    }

    /// Returns a human-readable time-ago string for the post date.
    private func timeAgo(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = formatter.date(from: dateString) else { return "" }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .day], from: date, to: now)

        if let hours = components.hour, hours < 24 {
            return "\(hours)hr"
        } else if let days = components.day, days < 7 {
            return "\(days)d"
        } else {
            return "1w"
        }
    }
}

#Preview {
    CovePostsView(
        viewModel: CoveModel(),
        onRefresh: {}
    )
} 