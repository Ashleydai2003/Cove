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
        
        // Use exact configuration that matches the working example
        let socketURL = "wss://socket.coveapp.co:3001"
        print("🔗 Connecting to: \(socketURL)")
        
        manager = SocketManager(
            socketURL: URL(string: socketURL)!,
            config: [
                .log(true),
                .compress,
                .connectParams(["token": token]),
                .forceWebsockets(true),
                .version(.three),       // 🔥 CRITICAL: Use Socket.IO v4 protocol (matches server v4.8.1)
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(1000)
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
        print("🚀 Connecting to WebSocket...")
        
        // First test basic connectivity
        testBasicConnectivity { isReachable in
            if isReachable {
                print("✅ Server is reachable, attempting WebSocket connection...")
                self.socket?.connect()
            } else {
                print("❌ Server is not reachable - network issue!")
            }
        }
    }
    
    private func testBasicConnectivity(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://socket.coveapp.co:3001")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(false)
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Server responded with status: \(httpResponse.statusCode)")
                    completion(true)
                } else {
                    print("⚠️  Unexpected response type")
                    completion(false)
                }
            }
        }.resume()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
} 