import SwiftUI

struct InvitesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InvitesViewModel()
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Colors.primaryDark)
                    }
                    
                    Spacer()
                    
                    Text("cove")
                        .font(.LibreBodoniBold(size: 32))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    // Empty space to center the title
                    Color.clear
                        .frame(width: 20)
                }
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Text("loading invites...")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                    }
                    Spacer()
                } else if viewModel.invites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "envelope")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("no pending invites")
                            .font(.LibreBodoniBold(size: 20))
                            .foregroundColor(Colors.primaryDark)
                        
                        Text("when friends invite you to coves,\nthey'll appear here")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    VStack(spacing: 32) {
                        // Pending invites header
                        VStack(spacing: 8) {
                            Text("you have \(viewModel.invites.count) pending invites")
                                .font(.LibreBodoniBold(size: 20))
                                .foregroundColor(Colors.primaryDark)
                                .multilineTextAlignment(.center)
                            
                            Text("tap to open!")
                                .font(.LibreBodoni(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Invites scroll view
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(viewModel.invites, id: \.id) { invite in
                                    InviteEnvelopeView(invite: invite) {
                                        viewModel.openInvite(invite)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchInvites()
        }
        .alert("Join Cove", isPresented: Binding(
            get: { viewModel.selectedInvite != nil },
            set: { if !$0 { viewModel.selectedInvite = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                viewModel.selectedInvite = nil
            }
            Button("Join") {
                if let invite = viewModel.selectedInvite {
                    viewModel.acceptInvite(invite)
                }
            }
            Button("Decline", role: .destructive) {
                if let invite = viewModel.selectedInvite {
                    viewModel.declineInvite(invite)
                }
            }
        } message: {
            if let invite = viewModel.selectedInvite {
                Text("Join \(invite.cove.name) in \(invite.cove.location)?")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

/// Individual envelope card for an invite
struct InviteEnvelopeView: View {
    let invite: InviteModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Envelope background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.91, blue: 0.82),
                                Color(red: 0.92, green: 0.86, blue: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                // Envelope flap
                VStack {
                    Triangle()
                        .fill(Color(red: 0.88, green: 0.80, blue: 0.68))
                        .frame(height: 60)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                
                // Content
                VStack(spacing: 12) {
                    Spacer()
                    
                    Text(invite.cove.name)
                        .font(.LibreBodoniBold(size: 18))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text(invite.cove.location)
                        .font(.LibreBodoni(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    if let senderName = invite.sender.name {
                        Text("from \(senderName)")
                            .font(.LibreBodoni(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(16)
            }
        }
        .frame(height: 180)
        .buttonStyle(PlainButtonStyle())
    }
}

/// Triangle shape for envelope flap
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    InvitesView()
} 