import SwiftUI
import FirebaseAuth

struct MessagingView: View {
    @EnvironmentObject private var appController: AppController
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: MessagingViewModel = AppController.shared.messagingViewModel
    @ObservedObject private var socketManager: SocketManagerService = SocketManagerService.shared

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            VStack {
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
                    
                    // Placeholder for future "New Message" button
                    Color.clear
                        .frame(width: 18)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // WebSocket Status (for testing)
                HStack {
                    Circle()
                        .fill(socketManager.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(socketManager.isConnected ? "Connected" : "Disconnected")
                        .font(.LeagueSpartan(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button("Test Connection") {
                        if socketManager.isConnected {
                            socketManager.disconnect()
                        } else {
                            // Get Firebase token and connect
                            if let currentUser = Auth.auth().currentUser {
                                currentUser.getIDToken { token, error in
                                    if let token = token {
                                        DispatchQueue.main.async {
                                            socketManager.connect(token: token)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .font(.LeagueSpartan(size: 12))
                    .foregroundColor(Colors.primaryDark)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .foregroundColor(Colors.primaryDark)
                    Text("loading conversations...")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                    Spacer()
                } else if viewModel.threads.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("no conversations yet")
                            .font(.LibreBodoniBold(size: 20))
                            .foregroundColor(Colors.primaryDark)

                        Text("start a conversation with your friends to see messages here")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    // Threads list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.threads) { thread in
                                ThreadRowView(thread: thread) {
                                    // Navigate to conversation
                                    viewModel.selectedThread = thread
                                    // TODO: Navigate to conversation view
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .onAppear {
            Log.debug("📱 MessagingView: onAppear - using shared viewModel with \(viewModel.threads.count) threads")
            Log.debug("📱 MessagingView: WebSocket status - \(socketManager.currentStatus)")
        }
    }
}

/// Individual thread row view
struct ThreadRowView: View {
    let thread: ThreadModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar placeholder
                Circle()
                    .fill(Colors.primaryDark.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("👤")
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(threadDisplayName)
                            .font(.LibreBodoniBold(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if thread.unreadCount > 0 {
                            Text("\(thread.unreadCount)")
                                .font(.LeagueSpartan(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Colors.primaryDark)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.content)
                            .font(.LibreBodoni(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No messages yet")
                            .font(.LibreBodoni(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                            .italic()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 86)
    }
    
    /// Computed property to get display name for thread
    private var threadDisplayName: String {
        // For now, show the first other member's name
        // In the future, this could be a group name or combined names
        let otherMembers = thread.members.filter { $0.userId != getCurrentUserId() }
        if let firstMember = otherMembers.first {
            return firstMember.user.name ?? "Unknown"
        }
        return "Unknown"
    }
    
    /// Helper to get current user ID
    private func getCurrentUserId() -> String {
        // TODO: Get from AppController or Auth
        return Auth.auth().currentUser?.uid ?? ""
    }
}

#Preview {
    MessagingView()
        .environmentObject(AppController.shared)
} 