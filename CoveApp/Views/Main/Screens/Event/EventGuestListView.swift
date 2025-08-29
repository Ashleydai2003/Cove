//
//  EventMembersSheet.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI
import Kingfisher

// MARK: - Event Guest List View
struct EventGuestListView: View {
    let eventId: String
    @ObservedObject var viewModel: EventPostViewModel
    let event: Event?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Images.backArrow
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    Text("guest list")
                        .font(.LibreBodoniBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                        .padding(.top, 16)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Images.backArrow
                        .opacity(0)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 16)
                
                // Tab picker using PillTabBar
                if event?.isHost == true {
                    VStack(spacing: 16) {
                        PillTabBar(
                            titles: ["Going", "Pending"],
                            selectedIndex: $selectedTab,
                            badges: [false, viewModel.pendingMembers.count > 0] // Show badge if there are pending members
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        // Content based on selected tab
                        if selectedTab == 0 {
                            // Going members tab
                            GuestListTab(
                                title: "Going",
                                members: viewModel.eventMembers.map { 
                                    GuestMember(
                                        id: $0.id,
                                        userId: $0.userId,
                                        userName: $0.userName,
                                        profilePhotoUrl: $0.profilePhotoUrl,
                                        dateText: formatDate($0.joinedAt),
                                        isPending: false
                                    )
                                },
                                isLoading: viewModel.isLoadingMembers,
                                hasMore: viewModel.hasMoreMembers,
                                onLoadMore: {
                                    viewModel.fetchEventMembers(eventId: eventId)
                                },
                                onAction: nil
                            )
                        } else {
                            // Pending members tab (host only)
                            GuestListTab(
                                title: "Pending Approval",
                                members: viewModel.pendingMembers.map { 
                                    GuestMember(
                                        id: $0.id,
                                        userId: $0.userId,
                                        userName: $0.userName,
                                        profilePhotoUrl: $0.profilePhotoUrl,
                                        dateText: formatDate($0.requestedAt),
                                        isPending: true
                                    )
                                },
                                isLoading: viewModel.isLoadingPending,
                                hasMore: viewModel.hasMorePending,
                                onLoadMore: {
                                    viewModel.fetchPendingMembers(eventId: eventId)
                                },
                                onAction: { member, action in
                                    viewModel.approveDeclineRSVP(rsvpId: member.id, action: action) { success in
                                        if success {
                                            if action == "approve" {
                                                // Refresh both lists after approval
                                                viewModel.fetchEventMembers(eventId: eventId, refresh: true)
                                                viewModel.fetchPendingMembers(eventId: eventId, refresh: true)
                                                // Also refresh the main event details to update counts
                                                viewModel.fetchEventDetails(eventId: eventId)
                                            } else if action == "decline" {
                                                // Just refresh pending list after decline
                                                viewModel.fetchPendingMembers(eventId: eventId, refresh: true)
                                                // Also refresh the main event details to update counts
                                                viewModel.fetchEventDetails(eventId: eventId)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                } else {
                    // Non-host users only see the going tab
                    GuestListTab(
                        title: "Going",
                        members: viewModel.eventMembers.map { 
                            GuestMember(
                                id: $0.id,
                                userId: $0.userId,
                                userName: $0.userName,
                                profilePhotoUrl: $0.profilePhotoUrl,
                                dateText: formatDate($0.joinedAt),
                                isPending: false
                            )
                        },
                        isLoading: viewModel.isLoadingMembers,
                        hasMore: viewModel.hasMoreMembers,
                        onLoadMore: {
                            viewModel.fetchEventMembers(eventId: eventId)
                        },
                        onAction: nil
                    )
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return "Joined \(displayFormatter.string(from: date))"
    }
}

// MARK: - Guest List Tab View
struct GuestListTab: View {
    let title: String
    let members: [GuestMember]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    let onAction: ((GuestMember, String) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(members) { member in
                    GuestRowView(
                        member: member,
                        onAction: onAction
                    )
                    .onAppear {
                        // Load more when reaching near the end
                        if member.id == members.last?.id && hasMore && !isLoading {
                            onLoadMore()
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                if members.isEmpty && !isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(title == "Going" ? "No confirmed guests yet" : "No pending requests")
                            .font(.LibreBodoni(size: 18))
                            .foregroundColor(.gray)
                        
                        Text(title == "Going" ? "People will appear here once they RSVP and are approved" : "Pending RSVP requests will appear here")
                            .font(.LibreBodoni(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

// MARK: - Guest Row View
struct GuestRowView: View {
    let member: GuestMember
    let onAction: ((GuestMember, String) -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            if let profilePhotoUrl = member.profilePhotoUrl {
                KFImage(profilePhotoUrl)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                    }
                    .resizable()
                    .scaledToFill()
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
            
            // Member name
            Text(member.userName.lowercased())
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
            
            Spacer()
            
            // Action buttons for pending members
            if member.isPending, let onAction = onAction {
                HStack(spacing: 8) {
                    Button(action: {
                        onAction(member, "decline")
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        onAction(member, "approve")
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Guest Member Model
struct GuestMember: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let profilePhotoUrl: URL?
    let dateText: String
    let isPending: Bool
}

#Preview {
    EventGuestListView(
        eventId: "test",
        viewModel: EventPostViewModel(),
        event: nil
    )
} 