import Foundation
import SocketIO
import FirebaseAuth

class SocketTest {
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    private var onConnectionStatusChange: ((Bool, String) -> Void)?

    init(onConnectionStatusChange: ((Bool, String) -> Void)? = nil) {
        self.onConnectionStatusChange = onConnectionStatusChange
        
        // Get Firebase token for testing
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user")
            onConnectionStatusChange?(false, "No authenticated user")
            return
        }
        
        print("🔐 Getting Firebase token for user: \(currentUser.uid)")
        print("🔧 Firebase Auth configuration:")
        print("  - Production mode: true")
        
        currentUser.getIDTokenForcingRefresh(true) { token, error in
            if let token = token {
                print("✅ Token received successfully")
                print("🔑 Token preview: \(String(token.prefix(50)))...")
                DispatchQueue.main.async {
                    self.setupSocket(with: token)
                }
            } else if let error = error {
                print("❌ Failed to get token: \(error.localizedDescription)")
                self.onConnectionStatusChange?(false, "Token Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupSocket(with token: String) {
        print("🔧 Setting up socket with token: \(String(token.prefix(20)))...")
        
        // Use exact configuration that matches the working Node.js tests
        let socketURL = "wss://socket.coveapp.co:3001"
        print("🔗 Connecting to: \(socketURL)")
        
        manager = SocketManager(
            socketURL: URL(string: socketURL)!,
            config: [
                .log(true),
                .compress,
                .connectParams(["token": token]),
                .extraHeaders(["Authorization": "Bearer \(token)"]),
                .forceWebsockets(true)
            ]
        )

        print("👉 Swift will hit:", manager.socketURL.absoluteString + "/socket.io/")
        print("Engine URL will be:", manager.socketURL.absoluteString + "/socket.io/")
        print("🔧 Socket configuration:")
        print("  - URL: \(socketURL)")
        print("  - Token: \(String(token.prefix(20)))...")
        print("  - Engine.IO version: default (v4)")
        print("  - Transport: WebSocket only (forced)")
        print("  - Query params: token=\(String(token.prefix(20)))...")
        print("  - Auth header: Bearer \(String(token.prefix(20)))...")

        socket = manager.defaultSocket

        // Add basic event listeners
        socket.on(clientEvent: .connect) { data, _ in
            print("✅ Connected to server")
            print("📊 Connection details:")
            print("  - Socket ID: \(self.socket?.sid ?? "unknown")")
            self.onConnectionStatusChange?(true, "Connected")
        }

        socket.on(clientEvent: .disconnect) { data, _ in
            print("🔌 Disconnected from server")
            if let reason = data.first as? String {
                print("  - Reason: \(reason)")
            }
            self.onConnectionStatusChange?(false, "Disconnected")
        }

        socket.on(clientEvent: .error) { data, _ in
            print("❌ Socket error:", data)
            self.onConnectionStatusChange?(false, "Connection Error")
        }

        socket.on(clientEvent: .statusChange) { data, _ in
            print("📡 Status change:", data)
        }

        socket.on(clientEvent: .reconnectAttempt) { data, _ in
            print("🔄 Reconnect attempt:", data)
        }

        socket.onAny { event in
            print("📥 Received event: \(event.event), data: \(event.items ?? [])")
        }
        
        // Listen for unauthorized events
        socket.on("unauthorized") { data, ack in
            print("🚫 Unauthorized:", data)
            self.onConnectionStatusChange?(false, "Unauthorized")
        }
    }

    func connect() {
        print("🚀 Connecting to WebSocket...")
        
        // Connect directly without HTTP test - WebSocket handles its own connectivity
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
} 