import SwiftUI
import FirebaseAuth

struct MessagingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isConnected = false
    @State private var connectionStatus = "Disconnected"
    @State private var socketTest: SocketTest?

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Colors.primaryDark)
                    }

                    Spacer()
                    
                    Text("messages")
                        .font(.LibreBodoniBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 18)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Connection Status
                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(connectionStatus)
                            .font(.LeagueSpartan(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    // Test Connection Button
                    Button("Test Socket Connection") {
                        testConnection()
                    }
                    .font(.LeagueSpartan(size: 14))
                    .foregroundColor(Colors.primaryDark)
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Placeholder Content
                VStack(spacing: 16) {
                    Image(systemName: "message")
                        .font(.system(size: 48))
                        .foregroundColor(Colors.primaryDark.opacity(0.3))

                    Text("messaging coming soon")
                        .font(.LibreBodoniBold(size: 20))
                        .foregroundColor(Colors.primaryDark)

                    Text("we're building a secure, real-time messaging system")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
        .onAppear {
            Log.debug("📱 MessagingView: onAppear")
        }
    }

    private func testConnection() {
        Log.debug("📱 MessagingView: Testing socket connection")
        
        connectionStatus = "Testing..."
        
        // Create and test socket connection
        socketTest = SocketTest()
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            socketTest?.connect()
            
            // Update status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isConnected = true
                connectionStatus = "Connected"
                
                // Disconnect after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    socketTest?.disconnect()
                    isConnected = false
                    connectionStatus = "Disconnected"
                }
            }
        }
    }
}

#Preview {
    MessagingView()
} 