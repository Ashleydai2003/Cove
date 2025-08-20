import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var appController: AppController
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: InboxViewModel = AppController.shared.inboxViewModel

    var body: some View {
        ZStack {
            Colors.background
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .foregroundColor(Colors.primaryDark)
                    Text("loading invites...")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                    Spacer()
                } else if viewModel.invites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("no invites yet")
                            .font(.LibreBodoniBold(size: 20))
                            .foregroundColor(Colors.primaryDark)

                        Text("when friends invite you to their coves, they'll appear here")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    VStack(spacing: 32) {
                        // Invites header
                        VStack(spacing: 8) {
                            if viewModel.unopenedInvites.count > 0 {
                                Text("you have \(viewModel.unopenedInvites.count) pending invites")
                                    .font(.LibreBodoniBold(size: 20))
                                    .foregroundColor(Colors.primaryDark)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("your invites")
                                    .font(.LibreBodoniBold(size: 20))
                                    .foregroundColor(Colors.primaryDark)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 30)

                        // Horizontal invites scroll view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Leading spacer for first card centering
                                Color.clear
                                    .frame(width: 50)

                                ForEach(viewModel.invites, id: \.id) { invite in
                                    if invite.isOpened {
                                        // Show InviteView for opened invites
                                        InviteView(
                                            invite: invite,
                                            onAccept: {
                                                Log.debug("📭 InboxView: Accept tapped for invite \(invite.id)")
                                                viewModel.acceptInvite(invite)
                                            },
                                            onDecline: {
                                                Log.debug("📭 InboxView: Decline tapped for invite \(invite.id)")
                                                viewModel.declineInvite(invite)
                                            }
                                        )
                                        .frame(width: 300, height: 520)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    } else {
                                        // Show envelope for unopened invites
                                        InviteEnvelopeView(invite: invite) {
                                            Log.debug("📭 InboxView: Opening invite: \(invite.id)")
                                            viewModel.openInvite(invite)
                                        }
                                        .frame(width: 260, height: 200)
                                    }
                                }

                                // Trailing spacer for last card centering
                                Color.clear
                                    .frame(width: 50)
                            }
                            .padding(.vertical, 10)
                        }
                        .clipped()

                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            // Don't call loadInvites() since we're using the shared viewModel
            // that's already been initialized and loaded during login
            Log.debug("📭 InboxView: onAppear - using shared viewModel with \(viewModel.invites.count) invites")
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
                // Envelope background - different style for opened invites
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: invite.isOpened ? [
                                // Muted colors for opened invites
                                Color(red: 0.90, green: 0.88, blue: 0.82),
                                Color(red: 0.85, green: 0.82, blue: 0.75)
                            ] : [
                                // Bright colors for unopened invites
                                Color(red: 0.95, green: 0.91, blue: 0.82),
                                Color(red: 0.92, green: 0.86, blue: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(invite.isOpened ? 0.08 : 0.15), radius: 8, x: 0, y: 4)

                // Envelope flap - different style for opened invites
                VStack {
                    Triangle()
                        .fill(Color(red: invite.isOpened ? 0.80 : 0.88, green: invite.isOpened ? 0.76 : 0.80, blue: invite.isOpened ? 0.68 : 0.68))
                        .frame(height: 50)
                        .padding(.top, 8)

                    Spacer()
                }

                // "Opened" indicator for opened invites
                if invite.isOpened {
                    VStack {
                        HStack {
                            Spacer()
                            Text("viewed")
                                .font(.LibreBodoni(size: 10))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                        }
                        Spacer()
                    }
                }

                // Content
                VStack(spacing: 10) {
                    Spacer()

                    Text(invite.cove.name)
                        .font(.LibreBodoniBold(size: 18))
                        .foregroundColor(invite.isOpened ? Colors.primaryDark.opacity(0.7) : Colors.primaryDark)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(invite.cove.location)
                        .font(.LibreBodoni(size: 14))
                        .foregroundColor(.gray.opacity(invite.isOpened ? 0.7 : 1.0))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    if let senderName = invite.sender.name {
                        Text("from \(senderName)")
                            .font(.LibreBodoni(size: 12))
                            .foregroundColor(.gray.opacity(invite.isOpened ? 0.6 : 0.8))
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(16)
            }
        }
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
    InboxView()
}
