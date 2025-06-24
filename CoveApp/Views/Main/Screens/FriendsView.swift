//
//  FriendsView.swift
//  Cove
//
//  Screen where user can add friends on Cove ("add friends on cove" on Figma)

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var appController: AppController

    // TODO: connect to API once endpoint is finished
    // For now, just pull from people in the same coves (implement get cove members API)
    @State private var mutuals: [FriendDTO] = [
        FriendDTO(
            id: "1",
            name: "angela nguyen",
            profilePhotoUrl: nil,
            friendshipId: "fship-1",
            createdAt: Date()
        ),
        FriendDTO(
            id: "2",
            name: "willa r baker",
            profilePhotoUrl: nil,
            friendshipId: "fship-2",
            createdAt: Date()
        ),
        FriendDTO(
            id: "3",
            name: "nina boord",
            profilePhotoUrl: nil,
            friendshipId: "fship-3",
            createdAt: Date()
        ),
        FriendDTO(
            id: "4",
            name: "felix roberts",
            profilePhotoUrl: nil,
            friendshipId: "fship-4",
            createdAt: Date()
        ),
        FriendDTO(
            id: "5",
            name: "tyler schuman",
            profilePhotoUrl: nil,
            friendshipId: "fship-5",
            createdAt: Date()
        )
    ]

    // TODO: replace once endpoint is finished
    @State private var pendingRequests: Set<String> = []

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack {
                        Button { appController.path.removeLast() } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    
                    Text("explore")
                        .font(.LibreBodoniBold(size: 25))
                        .foregroundStyle(Colors.primaryDark)
                    Text("send friend requests to mutuals you know")
                        .font(.LibreBodoni(size: 12))
                        .foregroundStyle(.black.opacity(0.7))
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                Button {
                    appController.path.append(.friendRequests)
                } label: {
                    HStack {
                        Text("friend requests")
                            .font(.LibreBodoniBold(size: 14))
                            .foregroundStyle(Color.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.black)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.black.opacity(1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)

                // MARK: — Mutuals List
                ScrollView {
                    VStack(spacing: 30) {
                        ForEach(mutuals) { friend in
                            HStack(spacing: 16) {
                                // Profile image (if URL exists, load with CachedAsyncImage; otherwise placeholder)
                                if let url = friend.profilePhotoUrl {
                                    CachedAsyncImage(
                                        url: url
                                    ) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                ProgressView()
                                                    .tint(.gray)
                                            )
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                } else {
                                    // PLACEHOLDER
                                    Images.profilePlaceholder
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                }

                                // Friend's name
                                Text(friend.name)
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundStyle(Color.black)

                                Spacer()

                                // "Request" / "Pending" button
                                if pendingRequests.contains(friend.friendshipId) {
                                    Text("pending")
                                        .font(.LibreBodoni(size: 12))
                                        .fontWeight(.medium)
                                        .frame(width: 100, height: 30)
                                        .background(Color.gray.opacity(0.3))
                                        .foregroundColor(.primary)
                                        .cornerRadius(11)
                                } else {
                                    Button {
                                        // Mark this friendshipId as "pending"
                                        pendingRequests.insert(friend.friendshipId)

                                        // TODO: make api call here
                                    } label: {
                                        Text("request")
                                            .font(.LibreBodoni(size: 12))
                                            .fontWeight(.medium)
                                            .frame(width: 100, height: 30)
                                            .background(Colors.primaryDark)
                                            .foregroundColor(.white)
                                            .cornerRadius(11)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                }

                Spacer(minLength: 0)
            }
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: — Preview

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
            .environmentObject(AppController.shared)
            .previewDevice("iPhone 13")
    }
}
