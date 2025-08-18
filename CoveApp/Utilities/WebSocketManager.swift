//
//  WebSocketManager.swift
//  Cove
//
//

import Foundation
import FirebaseAuth
import os

/// Secure WebSocket Manager for Socket.io connections
class WebSocketManager: ObservableObject {
    /// Singleton instance
    static let shared = WebSocketManager()
    
    /// Connection state
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    /// Socket.io connection
    private var socket: URLSessionWebSocketTask?
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    
    /// Connection status enum
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)
    }
    
    private init() {
        Log.debug("WebSocketManager initialized", category: "websocket")
    }
    
    // MARK: - Connection Management
    
    /// Connect to Socket.io server with Firebase authentication
    func connect() {
        guard !isConnected else {
            Log.debug("Already connected to WebSocket", category: "websocket")
            return
        }
        
        connectionStatus = .connecting
        Log.debug("Connecting to WebSocket: \(AppConstants.WebSocket.socketURL)", category: "websocket")
        
        // Get Firebase ID token for authentication
        Auth.auth().currentUser?.getIDToken { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                Log.error("Failed to get Firebase token: \(error.localizedDescription)", category: "websocket")
                self.connectionStatus = .error("Authentication failed")
                return
            }
            
            guard let token = token else {
                Log.error("No Firebase token available", category: "websocket")
                self.connectionStatus = .error("No authentication token")
                return
            }
            
            // Create WebSocket connection with authentication
            self.createWebSocketConnection(token: token)
        }
    }
    
    /// Create WebSocket connection with authentication
    private func createWebSocketConnection(token: String) {
        guard let url = URL(string: AppConstants.WebSocket.socketURL) else {
            Log.error("Invalid WebSocket URL: \(AppConstants.WebSocket.socketURL)", category: "websocket")
            connectionStatus = .error("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        socket = URLSession.shared.webSocketTask(with: request)
        socket?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Send authentication message
        sendAuthenticationMessage(token: token)
    }
    
    /// Send authentication message to Socket.io server
    private func sendAuthenticationMessage(token: String) {
        let authMessage = [
            "type": "auth",
            "token": token
        ]
        
        sendMessage(authMessage)
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        Log.debug("Disconnecting from WebSocket", category: "websocket")
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
        
        socket?.cancel()
        socket = nil
        
        isConnected = false
        connectionStatus = .disconnected
    }
    
    // MARK: - Message Handling
    
    /// Send message to WebSocket
    func sendMessage(_ message: [String: Any]) {
        guard let socket = socket else {
            Log.error("Cannot send message: WebSocket not connected", category: "websocket")
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            
            socket.send(webSocketMessage) { [weak self] error in
                if let error = error {
                    Log.error("Failed to send WebSocket message: \(error.localizedDescription)", category: "websocket")
                    self?.handleConnectionError(error)
                } else {
                    Log.debug("WebSocket message sent successfully", category: "websocket")
                }
            }
        } catch {
            Log.error("Failed to serialize WebSocket message: \(error.localizedDescription)", category: "websocket")
        }
    }
    
    /// Receive messages from WebSocket
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleReceivedMessage(message)
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                Log.error("WebSocket receive error: \(error.localizedDescription)", category: "websocket")
                self.handleConnectionError(error)
            }
        }
    }
    
    /// Handle received WebSocket message
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    handleSocketMessage(json)
                }
            } catch {
                Log.error("Failed to parse WebSocket message: \(error.localizedDescription)", category: "websocket")
            }
            
        case .string(let string):
            do {
                if let data = string.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    handleSocketMessage(json)
                }
            } catch {
                Log.error("Failed to parse WebSocket string message: \(error.localizedDescription)", category: "websocket")
            }
            
        @unknown default:
            Log.debug("Unknown WebSocket message type", category: "websocket")
        }
    }
    
    /// Handle Socket.io specific messages
    private func handleSocketMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            Log.debug("WebSocket message missing type", category: "websocket")
            return
        }
        
        switch type {
        case "auth_success":
            Log.debug("WebSocket authentication successful", category: "websocket")
            isConnected = true
            connectionStatus = .connected
            reconnectAttempts = 0
            
        case "auth_error":
            Log.error("WebSocket authentication failed", category: "websocket")
            connectionStatus = .error("Authentication failed")
            
        case "new_message":
            handleNewMessage(message)
            
        case "typing_start", "typing_stop":
            handleTypingIndicator(message)
            
        case "message_read":
            handleMessageRead(message)
            
        case "user_online", "user_offline":
            handleUserStatus(message)
            
        default:
            Log.debug("Received WebSocket message: \(type)", category: "websocket")
        }
    }
    
    // MARK: - Message Handlers
    
    private func handleNewMessage(_ message: [String: Any]) {
        // Handle new message notification
        Log.debug("New message received", category: "websocket")
        // TODO: Implement message handling logic
    }
    
    private func handleTypingIndicator(_ message: [String: Any]) {
        // Handle typing indicator
        Log.debug("Typing indicator received", category: "websocket")
        // TODO: Implement typing indicator logic
    }
    
    private func handleMessageRead(_ message: [String: Any]) {
        // Handle message read receipt
        Log.debug("Message read receipt received", category: "websocket")
        // TODO: Implement read receipt logic
    }
    
    private func handleUserStatus(_ message: [String: Any]) {
        // Handle user online/offline status
        Log.debug("User status update received", category: "websocket")
        // TODO: Implement user status logic
    }
    
    // MARK: - Error Handling & Reconnection
    
    private func handleConnectionError(_ error: Error) {
        Log.error("WebSocket connection error: \(error.localizedDescription)", category: "websocket")
        
        isConnected = false
        connectionStatus = .error(error.localizedDescription)
        
        // Attempt reconnection if we haven't exceeded max attempts
        if reconnectAttempts < maxReconnectAttempts {
            attemptReconnection()
        } else {
            Log.error("Max reconnection attempts reached", category: "websocket")
            connectionStatus = .error("Connection failed after \(maxReconnectAttempts) attempts")
        }
    }
    
    private func attemptReconnection() {
        reconnectAttempts += 1
        connectionStatus = .reconnecting
        
        Log.debug("Attempting WebSocket reconnection (\(reconnectAttempts)/\(maxReconnectAttempts))", category: "websocket")
        
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let delay = TimeInterval(pow(2.0, Double(reconnectAttempts - 1)))
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    // MARK: - Public Interface
    
    /// Send a message to a specific thread
    func sendMessage(to threadId: String, content: String) {
        let message = [
            "type": "send_message",
            "threadId": threadId,
            "content": content
        ]
        sendMessage(message)
    }
    
    /// Start typing indicator
    func startTyping(in threadId: String) {
        let message = [
            "type": "typing_start",
            "threadId": threadId
        ]
        sendMessage(message)
    }
    
    /// Stop typing indicator
    func stopTyping(in threadId: String) {
        let message = [
            "type": "typing_stop",
            "threadId": threadId
        ]
        sendMessage(message)
    }
    
    /// Mark message as read
    func markMessageAsRead(messageId: String) {
        let message = [
            "type": "mark_read",
            "messageId": messageId
        ]
        sendMessage(message)
    }
} 