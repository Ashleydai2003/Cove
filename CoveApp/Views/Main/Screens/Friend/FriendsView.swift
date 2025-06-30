import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let pageSize = 10
    
    init() {
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        Friends.fetchFriends(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let resp):
                self.friends.append(contentsOf: resp.friends)
                self.hasMore = resp.pagination.nextCursor != nil
                self.nextCursor = resp.pagination.nextCursor
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct FriendsView: View {
    @StateObject private var vm = FriendsViewModel()
    @State private var showMessageAlert = false
    @State private var selectedFriendName: String = ""
    
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
                Button(action: message) {
                    Text("message")
                        .font(.LibreBodoni(size: 10))
                        .frame(width: 65, height: 20)
                        .background(Colors.primaryDark)
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    FriendsView()
} 