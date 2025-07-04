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
    @State private var showMessageAlert = false
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
                        MemberRowView(
                            member: member,
                            currentUserId: appController.profileModel.userId,
                            friendsViewModel: appController.friendsViewModel,
                            mutualsViewModel: appController.mutualsViewModel,
                            onMessage: {
                                selectedMemberName = member.name
                                showMessageAlert = true
                            }
                        )
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
                            .foregroundColor(.gray)
                        
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
        // TODO: make alert 
        .alert("Direct messaging coming soon!", isPresented: $showMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("TODO: implement messaging")
        }
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
    let friendsViewModel: FriendsViewModel
    let mutualsViewModel: MutualsViewModel
    let onMessage: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            if let profilePhotoUrl = member.profilePhotoUrl {
                KFImage(profilePhotoUrl)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(maxWidth: 62, maxHeight: 62)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                    }
                    .onSuccess { result in
                        print("📸 Member profile photo loaded from: \(result.cacheType)")
                    }
                    .resizable()
                    .fade(duration: 0.2)
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
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
            
            // Smart button logic
            if member.id == currentUserId {
                // Don't show any button for the current user
                EmptyView()
            } else if isFriend {
                // Show message button for friends
                ActionButton.message {
                    onMessage()
                }
            } else if isPendingRequest {
                // Show pending button for users who already have a pending request
                ActionButton.pending()
            } else {
                // Show request button for non-friends
                ActionButton.request {
                    sendFriendRequest()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    /// Checks if the member is already a friend
    private var isFriend: Bool {
        return friendsViewModel.friends.contains { friend in
            friend.id == member.id
        }
    }
    
    /// Checks if there's already a pending friend request for this user
    private var isPendingRequest: Bool {
        return mutualsViewModel.pendingRequests.contains(member.id)
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