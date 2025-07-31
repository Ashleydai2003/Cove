import SwiftUI
import Kingfisher
import FirebaseAuth

/// FeedPostSummaryView: Displays a single post in the feed with author info at bottom left
struct FeedPostSummaryView: View {
    let post: CovePost
    @EnvironmentObject private var appController: AppController
    var viewModel: CoveModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time-ago label at top right (like EventSummaryView)
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
                    .foregroundColor(Colors.primaryDark)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 4)

                // Author info at bottom left (like EventSummaryView)
                HStack(spacing: 4) {
                    Text("posted by")
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(.black)
                    Text(post.authorName)
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(Colors.primaryDark)
                    Text("@")
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(.black)
                    Text(post.coveName)
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(Colors.primaryDark)
                    // TODO: only checkmark if author is verified
                    // This may require backend changes
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Colors.primaryDark)
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    // Like count and interaction at bottom right
                    Button(action: {
                        toggleLike(for: post)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(post.isLiked ? .red : .gray)
                                .font(.system(size: 14))
                            Text("\(post.likeCount)")
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 2)
                .padding(.top, 1)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    /// Toggles the like status for a post
    private func toggleLike(for post: CovePost) {
        guard let viewModel = viewModel else {
            Log.debug("No view model available for like toggle")
            return
        }
        
        viewModel.togglePostLike(postId: post.id) { success in
            if success {
                Log.debug("✅ Post like toggled successfully")
            } else {
                Log.debug("❌ Post like toggle failed")
            }
        }
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