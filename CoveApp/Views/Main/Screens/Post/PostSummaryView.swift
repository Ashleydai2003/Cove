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
    var viewModel: CoveModel?

    // Optimistic local state for like toggling
    @State private var localIsLiked: Bool = false
    @State private var localLikeCount: Int = 0
    @State private var initialized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Author info above post
            HStack(spacing: 10) {
                // Profile photo (use API URL or default image)
                if let profilePhotoUrl = post.authorProfilePhotoUrl, let url = URL(string: profilePhotoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Image("default_user_pfp")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                } else {
                    Image("default_user_pfp")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                
                // Author name and verification
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.authorName)
                            .font(.LibreBodoniSemiBold(size: 16))
                            .foregroundColor(.black)
                        // TODO: only checkmark if author is verified
                        // This may require backend changes
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Colors.primaryDark)
                            .font(.system(size: 14))
                    }
                    
                    // Show cove name under author name when in feed
                    if type == .feed {
                        HStack(spacing: 4) {
                            Text("@")
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                            Text(post.coveName)
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(Colors.primaryDark)
                        }
                    }
                }
                
                Spacer()
                
                // Time ago
                Text(timeAgo(post.createdAt))
                    .font(.LibreBodoniBold(size: 14))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 8)

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
                            .fill(Colors.hobbyBackground)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Like count and interaction
                HStack(spacing: 8) {
                    Button(action: {
                        toggleLike()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: localIsLiked ? "heart.fill" : "heart")
                                .foregroundColor(localIsLiked ? .red : .gray)
                                .font(.system(size: 14))
                            Text("\(localLikeCount)")
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .onAppear {
            if !initialized {
                localIsLiked = post.isLiked
                localLikeCount = post.likeCount
                initialized = true
            }
        }
    }

    private func toggleLike() {
        // Optimistic update
        localIsLiked.toggle()
        localLikeCount += localIsLiked ? 1 : -1

        guard let viewModel else { return }
        viewModel.togglePostLike(postId: post.id) { success in
            if !success {
                // Revert on failure
                localIsLiked.toggle()
                localLikeCount += localIsLiked ? 1 : -1
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