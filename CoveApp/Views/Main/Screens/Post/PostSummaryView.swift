import SwiftUI
import Kingfisher
import FirebaseAuth

/// The context in which the post summary is shown (for styling/layout)
enum PostSummaryType {
    case cove
    case feed
}

/// PostSummaryView: Displays a single post in the feed, including content and details.
struct PostSummaryView: View {
    let post: CovePost
    var type: PostSummaryType = .feed // Default type
    @EnvironmentObject private var appController: AppController

    var body: some View {
        NavigationLink(value: post.id) {
            VStack(alignment: .leading, spacing: 0) {
                // Time-ago label above the content
                HStack {
                    Spacer()
                    Text(timeAgo(post.createdAt))
                        .font(.LibreBodoniBold(size: 14))
                        .foregroundColor(.black)
                        .padding(.bottom, 2)
                }

                // Post content
                VStack(alignment: .leading, spacing: 8) {
                    // Post text content
                    Text(post.content)
                        .font(.LibreBodoniSemiBold(size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )

                    // Author info
                    HStack(spacing: 4) {
                        Text("by")
                            .font(.LibreBodoniSemiBold(size: 13))
                            .foregroundColor(.black)
                        Text(post.authorName)
                            .font(.LibreBodoniSemiBold(size: 13))
                            .foregroundColor(Colors.primaryDark)
                        if type != .cove {
                            Text("@")
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                            Text(post.coveName)
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(Colors.primaryDark)
                        }
                        // TODO: only checkmark if author is verified
                        // This may require backend changes
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Colors.primaryDark)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 2)

                    // Like count and interaction
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(post.isLiked ? .red : .gray)
                                .font(.system(size: 14))
                            Text("\(post.likeCount)")
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 5)
    }

    /// Returns a human-readable time-ago string for the post date.
    private func timeAgo(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return "" }
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)
        let months = Int(interval / 2592000)
        if minutes < 1 {
            return "just now"
        } else if hours < 1 {
            return "\(minutes)m"
        } else if days < 1 {
            return "\(hours)h"
        } else if weeks < 1 {
            return "\(days)d"
        } else if months < 1 {
            return "\(weeks)w"
        } else {
            return "\(months)mo"
        }
    }
} 