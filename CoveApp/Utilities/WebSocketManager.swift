//
//  WebSocketManager.swift
//  Cove
//
//  Created by AI Assistant on 7/19/25.
//

import Foundation
import FirebaseAuth
import SocketIO

/// Socket.io Manager Service using official Socket.IO-Client-Swift
class SocketManagerService: ObservableObject {
    static let shared = SocketManagerService()
    
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    private init() {}
    
    /// Connect to Socket.io server with Firebase token
    func connect(token: String) {
        // Use secure connectParams instead of query parameter
        guard let url = URL(string: AppConstants.WebSocket.socketURL) else {
            Log.error("Invalid WebSocket URL", category: "websocket")
            return
        }
        
        // Create Socket.io manager with secure connectParams
        manager = SocketManager(socketURL: url, config: [
            .log(true), // Enable logging for debugging
            .compress,
            .forceWebsockets(true), // Force WebSocket transport
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(1000),
            .forceNew(true), // Force new connection
            .connectParams(["token": token]) // Secure connectParams (not query param)
        ])
        
        guard let manager = manager else { return }
        
        // Get the default socket
        socket = manager.defaultSocket
        
        // Set up event handlers
        setupEventHandlers()
        
        // Connect to server with authentication
        connectionStatus = .connecting
        Log.debug("Connecting to Socket.io server", category: "websocket")
        
        // Debug: Log the token being sent (only first few chars for security)
        let tokenPreview = String(token.prefix(20)) + "..."
        Log.debug("Connecting with token: \(tokenPreview)", category: "websocket")
        Log.debug("Using URL: \(url.absoluteString)", category: "websocket")
        
        // Connect to server
        socket?.connect()
    }
    
    /// Set up Socket.io event handlers
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            Log.debug("Socket.io connected successfully", category: "websocket")
            Log.debug("Connection data: \(data)", category: "websocket")
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionStatus = .connected
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            Log.debug("Socket.io disconnected", category: "websocket")
            Log.debug("Disconnect data: \(data)", category: "websocket")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionStatus = .disconnected
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            Log.error("Socket.io error received", category: "websocket")
            Log.error("Error data: \(data)", category: "websocket")
            if let error = data.first as? String {
                Log.error("Socket.io error: \(error)", category: "websocket")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.connectionStatus = .error(error)
                }
            } else {
                Log.error("Socket.io error with unknown format: \(data)", category: "websocket")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.connectionStatus = .error("Unknown error")
                }
            }
        }
        
        socket.on(clientEvent: .reconnectAttempt) { data, ack in
            if let attempt = data.first as? Int {
                Log.debug("Socket.io reconnect attempt: \(attempt)", category: "websocket")
            }
        }
        
        socket.on(clientEvent: .reconnect) { data, ack in
            Log.debug("Socket.io reconnected", category: "websocket")
        }
        
        // Listen for unauthorized events from server
        socket.on("unauthorized") { [weak self] data, ack in
            Log.error("Socket unauthorized: \(data)", category: "websocket")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionStatus = .error("Unauthorized")
            }
        }
        
        // Listen for all events for debugging
        socket.onAny { event in
            Log.debug("Socket Event: \(event.event), Data: \(String(describing: event.items))", category: "websocket")
        }
        
        // Custom events
        socket.on("new_message") { [weak self] data, ack in
            Log.debug("Received new message event", category: "websocket")
            if let messageData = data.first as? [String: Any] {
                self?.handleNewMessage(messageData)
            }
        }
        
        socket.on("typing_start") { [weak self] data, ack in
            Log.debug("Received typing start event", category: "websocket")
            if let typingData = data.first as? [String: Any] {
                self?.handleTypingIndicator(typingData, isTyping: true)
            }
        }
        
        socket.on("typing_stop") { [weak self] data, ack in
            Log.debug("Received typing stop event", category: "websocket")
            if let typingData = data.first as? [String: Any] {
                self?.handleTypingIndicator(typingData, isTyping: false)
            }
        }
        
        socket.on("message_read") { [weak self] data, ack in
            Log.debug("Received message read event", category: "websocket")
            if let readData = data.first as? [String: Any] {
                self?.handleMessageRead(readData)
            }
        }
        
        socket.on("user_status") { [weak self] data, ack in
            Log.debug("Received user status event", category: "websocket")
            if let statusData = data.first as? [String: Any] {
                self?.handleUserStatus(statusData)
            }
        }
    }
    
    /// Send message to specific thread
    func sendMessage(threadId: String, content: String) {
        guard let socket = socket, isConnected else {
            Log.error("Cannot send message - not connected", category: "websocket")
            return
        }
        
        let messageData: [String: Any] = [
            "threadId": threadId,
            "content": content
        ]
        
        socket.emit("send_message", messageData)
        Log.debug("Sent message to thread \(threadId)", category: "websocket")
    }
    
    /// Send typing indicator
    func sendTyping(threadId: String, isTyping: Bool) {
        guard let socket = socket, isConnected else {
            Log.error("Cannot send typing indicator - not connected", category: "websocket")
            return
        }
        
        let event = isTyping ? "typing_start" : "typing_stop"
        let typingData: [String: Any] = [
            "threadId": threadId
        ]
        
        socket.emit(event, typingData)
        Log.debug("Sent \(event) for thread \(threadId)", category: "websocket")
    }
    
    /// Mark message as read
    func markMessageAsRead(messageId: String, threadId: String) {
        guard let socket = socket, isConnected else {
            Log.error("Cannot mark message as read - not connected", category: "websocket")
            return
        }
        
        let readData: [String: Any] = [
            "messageId": messageId,
            "threadId": threadId
        ]
        
        socket.emit("mark_read", readData)
        Log.debug("Marked message \(messageId) as read", category: "websocket")
    }
    
    /// Join a thread
    func joinThread(threadId: String) {
        guard let socket = socket, isConnected else {
            Log.error("Cannot join thread - not connected", category: "websocket")
            return
        }
        
        let joinData: [String: Any] = [
            "threadId": threadId
        ]
        
        socket.emit("join_thread", joinData)
        Log.debug("Joined thread \(threadId)", category: "websocket")
    }
    
    /// Leave a thread
    func leaveThread(threadId: String) {
        guard let socket = socket, isConnected else {
            Log.error("Cannot leave thread - not connected", category: "websocket")
            return
        }
        
        let leaveData: [String: Any] = [
            "threadId": threadId
        ]
        
        socket.emit("leave_thread", leaveData)
        Log.debug("Left thread \(threadId)", category: "websocket")
    }
    
    /// Handle new message event
    private func handleNewMessage(_ data: [String: Any]) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .newMessageReceived,
                object: nil,
                userInfo: data
            )
        }
    }
    
    /// Handle typing indicator
    private func handleTypingIndicator(_ data: [String: Any], isTyping: Bool) {
        var updatedData = data
        updatedData["isTyping"] = isTyping
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .typingIndicatorChanged,
                object: nil,
                userInfo: updatedData
            )
        }
    }
    
    /// Handle message read
    private func handleMessageRead(_ data: [String: Any]) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .messageRead,
                object: nil,
                userInfo: data
            )
        }
    }
    
    /// Handle user status
    private func handleUserStatus(_ data: [String: Any]) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .userStatusChanged,
                object: nil,
                userInfo: data
            )
        }
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        Log.debug("Disconnecting from WebSocket", category: "websocket")
        
        socket?.disconnect()
        socket = nil
        manager = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
        }
    }
    
    /// Get current status for UI
    var currentStatus: ConnectionStatus {
        return connectionStatus
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let typingIndicatorChanged = Notification.Name("typingIndicatorChanged")
    static let messageRead = Notification.Name("messageRead")
    static let userStatusChanged = Notification.Name("userStatusChanged")
} 