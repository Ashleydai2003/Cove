//
//  CovePost.swift
//  Cove
//
//  Refactored and documented for maintainability and best practices

import Foundation

/// CovePost: Represents a single post in a cove's feed.
/// - Used for post lists, post details, and post views.
struct CovePost: Decodable, Identifiable, ContentComparable {
    let id: String
    let content: String
    let coveId: String
    let coveName: String
    let authorId: String
    let authorName: String
    let authorProfilePhotoUrl: String?
    let isLiked: Bool
    let likeCount: Int
    let createdAt: String

    /// Returns the post date as a Date object (or now if parsing fails)
    var postDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return inputFormatter.date(from: createdAt) ?? Date()
    }

    /// Returns the post date as a formatted string (e.g., "March 5, 2024")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.createdAt) else { return "TBD" }
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    /// Returns the post time as a formatted string (e.g., "5:00 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.createdAt) else { return "TBD" }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// ContentComparable implementation - checks if meaningful content has changed
    func hasContentChanged(from other: CovePost) -> Bool {
        return content != other.content ||
               isLiked != other.isLiked ||
               likeCount != other.likeCount ||
               authorName != other.authorName ||
               coveName != other.coveName
    }
}

/// Post: Used for detailed post API responses (not just feed summaries)
struct Post: Decodable {
    let id: String
    let content: String
    let coveId: String
    let author: Author
    let cove: Cove
    let isLiked: Bool
    let likes: [PostLike]
    let createdAt: String
    let isAuthor: Bool

    var postDate: Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return inputFormatter.date(from: createdAt) ?? Date()
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.createdAt) else { return "TBD" }
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: self.createdAt) else { return "TBD" }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Author info for the post
    struct Author: Decodable {
        let id: String
        let name: String
    }

    /// Cove summary for the post
    struct Cove: Decodable {
        let id: String
        let name: String
    }
}

/// PostLike: Represents a like on a post
struct PostLike: Decodable {
    let id: String
    let userId: String
    let userName: String
    let createdAt: String
}

/// API response for post lists
struct PostsResponse: Decodable {
    let posts: [Post]?
    let pagination: Pagination?
}

/// API response for feed post lists
struct FeedPostsResponse: Decodable {
    let posts: [CovePost]?
    let pagination: Pagination?
} 