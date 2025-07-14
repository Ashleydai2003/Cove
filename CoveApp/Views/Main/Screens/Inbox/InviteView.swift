import SwiftUI
import Kingfisher

/// Invite detail view shown when user opens an envelope
struct InviteView: View {
    let invite: InviteModel
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        ZStack {
            // Background using app's primary dark color
            Colors.primaryDark
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 12) {
                    Text("you are invited to join")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                    
                    Text(invite.cove.name)
                        .font(.LibreBodoniBold(size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 32)
                
                // Cove cover photo
                Group {
                    if let coverPhotoUrlString = invite.cove.coverPhotoUrl,
                       let coverPhotoUrl = URL(string: coverPhotoUrlString) {
                        KFImage(coverPhotoUrl)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.white.opacity(0.9))
                                    .overlay(
                                        VStack(spacing: 6) {
                                            ProgressView()
                                                .foregroundColor(.gray)
                                            Text("Loading...")
                                                .font(.LibreBodoni(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            .onSuccess { result in
                                Log.debug("✅ InviteView: Successfully loaded cove cover photo from \(coverPhotoUrlString)")
                            }
                            .onFailure { error in
                                Log.debug("❌ InviteView: Failed to load cove cover photo from \(coverPhotoUrlString): \(error)")
                            }
                            .resizable()
                            .aspectRatio(3/2, contentMode: .fill)
                            .clipped()
                            .onAppear {
                            }
                    } else {
                        Image("default_cove_pfp")
                            .resizable()
                            .aspectRatio(3/2, contentMode: .fill)
                            .clipped()
                            .onAppear {
                                Log.debug("🔄 InviteView: Using default cover photo placeholder (no URL) for invite \(invite.id)")
                            }
                    }
                }
                .frame(maxHeight: .infinity)
                .id("photo-\(invite.id)-\(invite.cove.coverPhotoUrl ?? "none")")  // Force refresh when photo URL changes
                
                // Bottom section
                VStack(spacing: 0) {
                    // Location
                    Text(invite.cove.location)
                        .font(.LibreBodoniBold(size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                    
                    // Message section
                    if let message = invite.message, !message.isEmpty {
                        VStack(spacing: 8) {
                            Text("message from the host:")
                                .font(.LibreBodoni(size: 14))
                                .foregroundColor(.white)
                            
                            Text(message)
                                .font(.LibreBodoni(size: 14))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            Log.debug("🟢 ACCEPT BUTTON TAPPED for invite: \(invite.id)")
                            onAccept()
                        }) {
                            Text("join now")
                                .font(.LibreBodoniBold(size: 14))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(Color.white)
                                .cornerRadius(22)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            Log.debug("🔴 DECLINE BUTTON TAPPED for invite: \(invite.id)")
                            onDecline()
                        }) {
                            Text("decline")
                                .font(.LibreBodoniBold(size: 14))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

#Preview {
    // Sample invite for preview
    let sampleInvite = InviteModel(
        id: "sample-id",
        message: "hi angela, congrats on graduating! we'd love you to join our Cove and stay connected with us.",
        isOpened: true,
        createdAt: "2024-01-01T12:00:00Z",
        cove: InviteModel.InviteCove(
            id: "cove-id",
            name: "Stanford Young Alumni SF",
            description: "A great place to hang out",
            location: "San Francisco, CA",
            coverPhotoId: "cover-photo-id",
            coverPhotoUrl: "https://example.com/sample-cover-photo.jpg"
        ),
        sentBy: InviteModel.InviteSender(
            id: "sender-id",
            name: "John Doe",
            profilePhotoId: "profile-photo-id"
        )
    )
    
    InviteView(
        invite: sampleInvite,
        onAccept: {},
        onDecline: {}
    )
} 
