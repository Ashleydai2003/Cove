import Foundation
import SocketIO
import FirebaseAuth

class SocketTest {
    private var manager: SocketManager!
    private var socket: SocketIOClient!

    init() {
        // Get Firebase token for testing
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user")
            return
        }
        
        currentUser.getIDTokenForcingRefresh(true) { token, error in
            if let token = token {
                DispatchQueue.main.async {
                    self.setupSocket(with: token)
                }
            } else if let error = error {
                print("❌ Failed to get token: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupSocket(with token: String) {
        print("🔧 Setting up socket with token: \(String(token.prefix(20)))...")
        
        // Try using Authorization header approach
        manager = SocketManager(
            socketURL: URL(string: "wss://socket.coveapp.co:3001")!,
            config: [
                .log(true),
                .forceWebsockets(true),
                .extraHeaders(["Authorization": "Bearer \(token)"])
            ]
        )

        socket = manager.defaultSocket

        // Add basic event listeners
        socket.on(clientEvent: .connect) { data, ack in
            print("✅ Connected to server")
        }

        socket.on(clientEvent: .disconnect) { data, ack in
            print("🔌 Disconnected from server")
        }

        socket.on(clientEvent: .error) { data, ack in
            print("❌ Socket error:", data)
        }

        socket.on(clientEvent: .statusChange) { data, ack in
            print("📡 Status change:", data)
        }

        socket.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 Reconnect attempt:", data)
        }

        socket.onAny { event in
            print("📥 Received event: \(event.event), data: \(event.items ?? [])")
        }
        
        // Listen for unauthorized events
        socket.on("unauthorized") { data, ack in
            print("🚫 Unauthorized:", data)
        }
    }

    func connect() {
        print("🚀 Connecting to Socket.IO...")
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }
} 