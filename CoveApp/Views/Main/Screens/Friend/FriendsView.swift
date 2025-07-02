import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var appController: AppController
    @State private var showMessageAlert = false
    @State private var selectedFriendName: String = ""
    
    // Use the shared instance from AppController
    private var vm: FriendsViewModel {
        appController.friendsViewModel
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                Colors.faf8f4.ignoresSafeArea()
                
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
                                        .foregroundColor(.gray)
                                    
                                    Text("no friends yet!")
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                            } else {
                                ForEach(vm.friends) { friend in
                                    FriendRowView(
                                        name: friend.name,
                                        imageUrl: friend.profilePhotoUrl,
                                        onMessage: {
                                            selectedFriendName = friend.name
                                            showMessageAlert = true
                                        }
                                    )
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
                    
                    Spacer(minLength: 0)
                }
                .safeAreaPadding()
            }
        }
        .alert("Direct messaging coming soon!", isPresented: $showMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("TODO: implement messaging")
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            vm.loadNextPageIfStale()
        }
    }
}

struct FriendRowView: View {
    let name: String
    var imageUrl: URL? = nil
    var onMessage: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            if let url = imageUrl {
                AsyncImage(url: url) { img in img.resizable() } placeholder: {
                    Images.smily.resizable()
                }
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Images.smily
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