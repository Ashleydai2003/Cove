//
//  FriendsView.swift
//  Cove
//
//  Screen where user can add friends on Cove ("add friends on cove" on Figma)

import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var mutuals: [RecommendedFriendDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingRequests: Set<String> = []
    
    private let pageSize = 10
    
    init() {
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        RecommendedFriends.fetchRecommendedFriends(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                self.mutuals.append(contentsOf: response.users)
                self.hasMore = response.pagination.hasMore
                self.nextCursor = response.pagination.nextCursor
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func sendFriendRequest(to userId: String) {
        // Mark as pending immediately for better UX
        pendingRequests.insert(userId)
        
        // Make API call to send friend request
        NetworkManager.shared.post(
            endpoint: "/send-friend-request",
            parameters: ["toUserIds": [userId]]
        ) { [weak self] (result: Result<SendRequestResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Keep it as pending - the user will see it in their friend requests
                    print("✅ Friend request sent successfully to \(userId)")
                case .failure(let error):
                    // Remove from pending if the request failed
                    self?.pendingRequests.remove(userId)
                    self?.errorMessage = error.localizedDescription
                    print("❌ Failed to send friend request: \(error)")
                }
            }
        }
    }
}

struct FriendsView: View {
    @EnvironmentObject var appController: AppController
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
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
                if viewModel.isLoading && viewModel.mutuals.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Text("loading mutuals...")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(error)
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            ForEach(viewModel.mutuals) { mutual in
                                HStack(spacing: 16) {
                                    // Profile image (if URL exists, load with CachedAsyncImage; otherwise placeholder)
                                    if let url = mutual.profilePhotoUrl {
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        // Friend's name
                                        Text(mutual.name)
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundStyle(Color.black)
                                        
                                        // Shared cove count
                                        Text("\(mutual.sharedCoveCount) shared cove\(mutual.sharedCoveCount == 1 ? "" : "s")")
                                            .font(.LibreBodoni(size: 12))
                                            .foregroundStyle(Color.black.opacity(0.6))
                                    }

                                    Spacer()

                                    // "Request" / "Pending" button
                                    if viewModel.pendingRequests.contains(mutual.id) {
                                        Text("pending")
                                            .font(.LibreBodoni(size: 12))
                                            .fontWeight(.medium)
                                            .frame(width: 100, height: 30)
                                            .background(Color.gray.opacity(0.3))
                                            .foregroundColor(.primary)
                                            .cornerRadius(11)
                                    } else {
                                        Button {
                                            viewModel.sendFriendRequest(to: mutual.id)
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
                                .onAppear {
                                    // Load more if this is one of the last items
                                    if mutual.id == viewModel.mutuals.last?.id {
                                        viewModel.loadNextPage()
                                    }
                                }
                            }
                            
                            if viewModel.isLoading && !viewModel.mutuals.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Colors.primaryDark)
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.top, 20)
                    }
                }

                Spacer(minLength: 0)
            }
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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
