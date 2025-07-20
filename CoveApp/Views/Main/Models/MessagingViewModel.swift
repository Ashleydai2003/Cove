import Foundation
import Combine
import SwiftUI
import UIKit // For haptic feedback

@MainActor
class MessagingViewModel: ObservableObject {
    @Published var threads: [ThreadModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedThread: ThreadModel?
    @Published var messages: [MessageModel] = []
    @Published var isTyping = false
    @Published var typingUsers: Set<String> = []

    /// Computed property to get threads with unread messages
    var unreadThreads: [ThreadModel] {
        return threads.filter { $0.unreadCount > 0 }
    }

    /// Whether there are unread messages that should trigger showing the messaging
    var hasUnreadMessages: Bool {
        return !unreadThreads.isEmpty
    }

    /// Initializes the messaging model - called on login/after onboarding
    func initialize() {
        fetchThreads()
    }

    /// Fetches user's messaging threads
    func fetchThreads() {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.get(
            endpoint: "/threads",
            parameters: nil
        ) { [weak self] (result: Result<ThreadsResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.threads = response.threads
                    Log.debug("📱 MessagingViewModel: Loaded \(self.threads.count) threads")

                case .failure(let error):
                    Log.error("Failed to fetch threads: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load conversations: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Loads threads - convenience method for MessagingView
    func loadThreads() {
        fetchThreads()
    }

    /// Creates a new thread with participants
    func createThread(participantIds: [String], completion: @escaping (Result<ThreadModel, Error>) -> Void) {
        Log.debug("📱 MessagingViewModel: Creating thread with participants: \(participantIds)")

        NetworkManager.shared.post(
            endpoint: "/create-thread",
            parameters: ["participantIds": participantIds]
        ) { [weak self] (result: Result<CreateThreadResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Add new thread to the beginning of the list
                    withAnimation {
                        self.threads.insert(response.thread, at: 0)
                    }
                    completion(.success(response.thread))
                    Log.debug("📱 MessagingViewModel: Successfully created thread \(response.thread.id)")

                case .failure(let error):
                    Log.error("createThread failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to create conversation: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }

    /// Sends a message to a thread
    func sendMessage(threadId: String, content: String, completion: @escaping (Result<MessageModel, Error>) -> Void) {
        Log.debug("📱 MessagingViewModel: Sending message to thread \(threadId)")

        NetworkManager.shared.post(
            endpoint: "/send-message",
            parameters: [
                "threadId": threadId,
                "content": content
            ]
        ) { [weak self] (result: Result<SendMessageResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Update the thread's last message
                    if let threadIndex = self.threads.firstIndex(where: { $0.id == threadId }) {
                        var updatedThreads = self.threads
                        // Create a new thread with updated lastMessage
                        let updatedThread = ThreadModel(
                            id: updatedThreads[threadIndex].id,
                            createdAt: updatedThreads[threadIndex].createdAt,
                            updatedAt: response.messageData.createdAt,
                            lastMessageId: response.messageData.id,
                            lastMessage: response.messageData,
                            members: updatedThreads[threadIndex].members,
                            unreadCount: updatedThreads[threadIndex].unreadCount
                        )
                        updatedThreads[threadIndex] = updatedThread
                        withAnimation {
                            self.threads = updatedThreads
                        }
                    }

                    // Add message to current thread if it's selected
                    if self.selectedThread?.id == threadId {
                        withAnimation {
                            self.messages.append(response.messageData)
                        }
                    }

                    completion(.success(response.messageData))
                    Log.debug("📱 MessagingViewModel: Successfully sent message")

                case .failure(let error):
                    Log.error("sendMessage failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }

    /// Loads messages for a specific thread
    func loadMessages(threadId: String, limit: Int = 50, cursor: String? = nil) {
        Log.debug("📱 MessagingViewModel: Loading messages for thread \(threadId)")

        var parameters: [String: Any] = ["limit": limit]
        if let cursor = cursor {
            parameters["cursor"] = cursor
        }

        NetworkManager.shared.get(
            endpoint: "/thread-messages",
            parameters: parameters
        ) { [weak self] (result: Result<ThreadMessagesResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if cursor == nil {
                        // First load - replace all messages
                        self.messages = response.messages
                    } else {
                        // Pagination - prepend older messages
                        self.messages.insert(contentsOf: response.messages, at: 0)
                    }
                    Log.debug("📱 MessagingViewModel: Loaded \(response.messages.count) messages")

                case .failure(let error):
                    Log.error("Failed to load messages: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Marks a message as read
    func markMessageAsRead(messageId: String) {
        Log.debug("📱 MessagingViewModel: Marking message \(messageId) as read")

        NetworkManager.shared.post(
            endpoint: "/mark-message-read",
            parameters: ["messageId": messageId]
        ) { (result: Result<MarkReadResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Log.debug("📱 MessagingViewModel: Successfully marked message as read")
                case .failure(let error):
                    Log.error("markMessageAsRead failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Updates user's FCM token for push notifications
    func updateFCMToken(token: String) {
        Log.debug("📱 MessagingViewModel: Updating FCM token")

        NetworkManager.shared.post(
            endpoint: "/update-fcm-token",
            parameters: ["fcmToken": token]
        ) { (result: Result<UpdateFCMTokenResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Log.debug("📱 MessagingViewModel: Successfully updated FCM token")
                case .failure(let error):
                    Log.error("updateFCMToken failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Clears all data when user logs out
    func clear() {
        threads = []
        messages = []
        selectedThread = nil
        isLoading = false
        errorMessage = nil
        isTyping = false
        typingUsers.removeAll()
    }
    
    // MARK: - WebSocket Event Handlers
    
    /// Handle incoming message from WebSocket
    func handleIncomingMessage(_ message: MessageModel) {
        Log.debug("📱 MessagingViewModel: Handling incoming message for thread \(message.threadId)")
        
        // Add message to current thread if it's selected
        if selectedThread?.id == message.threadId {
            withAnimation {
                messages.append(message)
            }
        }
        
        // Update thread's last message
        if let threadIndex = threads.firstIndex(where: { $0.id == message.threadId }) {
            var updatedThreads = threads
            let updatedThread = ThreadModel(
                id: updatedThreads[threadIndex].id,
                createdAt: updatedThreads[threadIndex].createdAt,
                updatedAt: message.createdAt,
                lastMessageId: message.id,
                lastMessage: message,
                members: updatedThreads[threadIndex].members,
                unreadCount: updatedThreads[threadIndex].unreadCount
            )
            updatedThreads[threadIndex] = updatedThread
            withAnimation {
                threads = updatedThreads
            }
        }
    }
    
    /// Handle typing indicator from WebSocket
    func handleTypingIndicator(threadId: String, userId: String, isTyping: Bool) {
        Log.debug("📱 MessagingViewModel: Handling typing indicator for thread \(threadId)")
        
        if isTyping {
            typingUsers.insert(userId)
        } else {
            typingUsers.remove(userId)
        }
        
        // Only update if this is the current thread
        if selectedThread?.id == threadId {
            withAnimation {
                self.isTyping = !typingUsers.isEmpty
            }
        }
    }
    
    /// Handle message read receipt from WebSocket
    func handleMessageRead(messageId: String, userId: String, threadId: String) {
        Log.debug("📱 MessagingViewModel: Handling read receipt for message \(messageId)")
        
        // Update message read status if it's in the current thread
        if selectedThread?.id == threadId {
            // Find and update the message's read status
            if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
                let existingMessage = messages[messageIndex]
                
                // Check if read receipt already exists
                let existingRead = existingMessage.reads.first { $0.userId == userId }
                if existingRead == nil {
                    let newRead = MessageModel.MessageRead(
                        id: UUID().uuidString,
                        messageId: messageId,
                        userId: userId,
                        readAt: ISO8601DateFormatter().string(from: Date()),
                        user: MessageModel.MessageSender(id: userId, name: nil)
                    )
                    
                    // Create new message with updated reads array
                    let updatedMessage = MessageModel(
                        id: existingMessage.id,
                        threadId: existingMessage.threadId,
                        senderId: existingMessage.senderId,
                        content: existingMessage.content,
                        createdAt: existingMessage.createdAt,
                        sender: existingMessage.sender,
                        reads: existingMessage.reads + [newRead]
                    )
                    
                    // Create new messages array with updated message
                    var updatedMessages = messages
                    updatedMessages[messageIndex] = updatedMessage
                    
                    withAnimation {
                        messages = updatedMessages
                    }
                }
            }
        }
    }
    
    /// Handle user status update from WebSocket
    func handleUserStatus(userId: String, threadId: String, isOnline: Bool) {
        Log.debug("📱 MessagingViewModel: Handling user status for user \(userId)")
        
        // This could be used to show online/offline indicators
        // For now, we'll just log it
        if isOnline {
            Log.debug("User \(userId) is online")
        } else {
            Log.debug("User \(userId) is offline")
        }
    }
}

// MARK: - Response Models

/// Response from /threads API
struct ThreadsResponse: Decodable {
    let threads: [ThreadModel]
}

/// Response from /create-thread API
struct CreateThreadResponse: Decodable {
    let message: String
    let thread: ThreadModel
}

/// Response from /send-message API
struct SendMessageResponse: Decodable {
    let message: String
    let messageData: MessageModel
}

/// Response from /thread-messages API
struct ThreadMessagesResponse: Decodable {
    let messages: [MessageModel]
    let nextCursor: String?
}

/// Response from /mark-message-read API
struct MarkReadResponse: Decodable {
    let message: String
}

/// Response from /update-fcm-token API
struct UpdateFCMTokenResponse: Decodable {
    let message: String
}

// MARK: - Data Models

/// Thread model for messaging conversations
struct ThreadModel: Decodable, Identifiable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let lastMessageId: String?
    let lastMessage: MessageModel?
    let members: [ThreadMember]
    let unreadCount: Int

    struct ThreadMember: Decodable {
        let id: String
        let userId: String
        let joinedAt: String
        let user: ThreadUser
    }

    struct ThreadUser: Decodable {
        let id: String
        let name: String?
    }
}

/// Message model for individual messages
struct MessageModel: Decodable, Identifiable {
    let id: String
    let threadId: String
    let senderId: String
    let content: String
    let createdAt: String
    let sender: MessageSender
    let reads: [MessageRead]

    struct MessageSender: Decodable {
        let id: String
        let name: String?
    }

    struct MessageRead: Decodable {
        let id: String
        let messageId: String
        let userId: String
        let readAt: String
        let user: MessageSender
    }
} 