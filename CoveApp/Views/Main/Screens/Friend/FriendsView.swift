import SwiftUI
import Kingfisher

// TopBannerView defined in Shared

struct FriendsView: View {
    @EnvironmentObject var appController: AppController
    @State private var showMessageBanner = false
    @State private var selectedFriendName: String = ""

    // Use the shared instance from AppController
    private var vm: FriendsViewModel {
        appController.friendsViewModel
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Error banner
                    if let msg = vm.errorMessage {
                        Text(msg)
                            .font(.LeagueSpartan(size: 12))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.cornerRadius(8))
                            .padding(.horizontal, 20)
                            .transition(.slide)
                    }

                    // Friends list
                    ScrollView {
                        LazyVStack(spacing: 36) {
                            if vm.friends.isEmpty && !vm.isLoading {
                                // No friends message
                                VStack(spacing: 16) {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 40))
                                        .foregroundColor(Colors.primaryDark)

                                    Text("no friends yet – say hi to someone!")
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(Colors.primaryDark)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                            } else {
                                ForEach(vm.friends) { friend in
                                    NavigationLink(destination: FriendProfileView(userId: friend.id, initialPhotoUrl: friend.profilePhotoUrl)) {
                                        FriendRowView(
                                             id: friend.id,
                                             name: friend.name,
                                             imageUrl: friend.profilePhotoUrl,
                                             onMessage: {
                                                 selectedFriendName = friend.name
                                                 withAnimation { showMessageBanner = true }
                                             }
                                         )
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if friend.id == vm.friends.last?.id {
                                            vm.loadNextPage()
                                        }
                                    }
                                }

                                if vm.isLoading {
                                    ProgressView().padding()
                                }
                            }
                        }
                        .padding(.top, 30)
                    }
                    .refreshable {
                        await withCheckedContinuation { continuation in
                            vm.refreshFriends {
                                continuation.resume()
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .safeAreaPadding()
            }
        }
        // Top banner for messaging placeholder
        .overlay(
            AlertBannerView(message: "direct messaging coming soon!", isVisible: $showMessageBanner)
                .animation(.easeInOut, value: showMessageBanner)
        )
        .navigationBarBackButtonHidden()
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            // Load friends if not already cached (will use cached data if available)
            vm.loadNextPageIfStale()
        }
    }
}

struct FriendRowView: View {
    let id: String
    let name: String
    var imageUrl: URL? = nil
    var onMessage: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let url = imageUrl {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Images.smily.resizable()
                    }
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image("default_user_pfp")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }

            Text(name)
                .font(.LibreBodoni(size: 14))
                .foregroundStyle(Color.black)

            Spacer()

            if let message = onMessage {
                ActionButton.message {
                    message()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    FriendsView()
}
