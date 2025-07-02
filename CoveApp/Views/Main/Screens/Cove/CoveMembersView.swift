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
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Member count header
                if let cove = viewModel.cove {
                    HStack {
                        Text("\(cove.stats.memberCount) members")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 18))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                // Members list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.members) { member in
                        MemberRowView(member: member) {
                            selectedMemberName = member.name
                            showMessageAlert = true
                        }
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
        .alert("Direct messaging coming soon!", isPresented: $showMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("TODO: implement messaging")
        }
    }
}

/// MemberRowView: Individual member row component
struct MemberRowView: View {
    let member: CoveMember
    let onMessage: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            if let profilePhotoUrl = member.profilePhotoUrl {
                KFImage(profilePhotoUrl)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
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
            
            // Message button (TODO: implement messaging)
            ActionButton.message {
                onMessage()
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CoveMembersView(
        viewModel: CoveModel(),
        onRefresh: {}
    )
} 