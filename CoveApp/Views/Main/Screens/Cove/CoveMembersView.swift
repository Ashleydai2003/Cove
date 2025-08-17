//
//  CoveMembersView.swift
//  Cove
//
//  Created by Ashley Dai on 7/1/25.
//

import SwiftUI
import Kingfisher

/// CoveMembersView: Reusable component for displaying cove members
/// - Shows scrollable list of members with pull-to-refresh
/// - Displays member count and member details
struct CoveMembersView: View {
    @ObservedObject var viewModel: CoveModel
    let onRefresh: () async -> Void
    @State private var showMessageBanner = false
    @State private var selectedMemberName: String = ""
    @State private var showSendInvites = false
    @EnvironmentObject var appController: AppController

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Member count header with optional + button for admins
                if let cove = viewModel.cove {
                    HStack {
                        Text("\(cove.stats.memberCount) members")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 18))

                        Spacer()

                        // Show + button if current user is admin
                        if viewModel.isCurrentUserAdmin {
                            Button(action: {
                                showSendInvites = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Colors.primaryDark)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Members list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.members) { member in
                        NavigationLink(destination: FriendProfileView(userId: member.id, initialPhotoUrl: member.profilePhotoUrl)) {
                            MemberRowView(
                                member: member,
                                currentUserId: appController.profileModel.userId,
                                friendsViewModel: appController.friendsViewModel,
                                mutualsViewModel: appController.mutualsViewModel,
                                requestsViewModel: appController.requestsViewModel,
                                onMessage: {
                                    selectedMemberName = member.name
                                    withAnimation { showMessageBanner = true }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            viewModel.loadMoreMembersIfNeeded(currentMember: member)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Loading indicator for members
                if viewModel.isRefreshingMembers {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                // Empty state
                if viewModel.members.isEmpty && !viewModel.isRefreshingMembers {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 40))
                            .foregroundColor(Colors.primaryDark)

                        Text("no members found")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                }

                Spacer(minLength: 24)
            }
        }
        .refreshable {
            await onRefresh()
        }
        // Messaging placeholder banner
        .overlay(
            AlertBannerView(message: "direct messaging coming soon!", isVisible: $showMessageBanner)
                .animation(.easeInOut, value: showMessageBanner)
        )
        .sheet(isPresented: $showSendInvites) {
            if let cove = viewModel.cove {
                SendInvitesView(
                    coveId: cove.id,
                    coveName: cove.name
                )
            }
        }
    }
}

/// MemberRowView: Individual member row component
struct MemberRowView: View {
    let member: CoveMember
    let currentUserId: String
    @ObservedObject var friendsViewModel: FriendsViewModel
    @ObservedObject var mutualsViewModel: MutualsViewModel
    @ObservedObject var requestsViewModel: RequestsViewModel
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            if let profilePhotoUrl = member.profilePhotoUrl {
                KFImage(profilePhotoUrl)
                    .resizable()
                    .placeholder {
                        Images.smily.resizable()
                    }
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Image("default_user_pfp")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }

            // Member info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoniBold(size: 16))

                Text(member.role.capitalized)
                    .foregroundStyle(Colors.k292929)
                    .font(.LibreBodoni(size: 12))
            }

            Spacer()

            // Smart button logic according to requirements
            if member.id == currentUserId {
                EmptyView() // No button for self
            } else if let incomingReq = incomingRequest {
                // They sent us a request → accept / delete options
                HStack(spacing: 8) {
                    ActionButton(
                        title: "accept",
                        width: 80,
                        height: 32,
                        backgroundColor: Colors.primaryDark,
                        textColor: .white,
                        font: .LibreBodoni(size: 14),
                        cornerRadius: 8) {
                            requestsViewModel.accept(incomingReq)
                        }
                    ActionButton(
                        title: "delete",
                        width: 80,
                        height: 32,
                        backgroundColor: Color.gray.opacity(0.3),
                        textColor: Colors.primaryDark,
                        font: .LibreBodoni(size: 14),
                        cornerRadius: 8) {
                            requestsViewModel.reject(incomingReq)
                        }
                }
            } else if isOutgoingPending {
                // We already sent request → pending
                ActionButton.pending()
            } else if isFriend {
                // Friends → message button
                ActionButton.message { onMessage() }
            } else {
                // Not friend and no pending requests → request button
                ActionButton.request { sendFriendRequest() }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    /// Outgoing pending request
    private var isOutgoingPending: Bool {
        return mutualsViewModel.pendingRequests.contains(member.id)
    }

    /// Incoming friend request from this member if exists
    private var incomingRequest: RequestDTO? {
        return requestsViewModel.requests.first { $0.sender.id == member.id }
    }

    /// Checks if the member is already a friend
    private var isFriend: Bool {
        return friendsViewModel.friends.contains { $0.id == member.id }
    }

    // MARK: - Actions

    /// Sends a friend request to this member
    private func sendFriendRequest() {
        mutualsViewModel.sendFriendRequest(to: member.id)
    }
}

#Preview {
    CoveMembersView(
        viewModel: CoveModel(),
        onRefresh: {}
    )
}
