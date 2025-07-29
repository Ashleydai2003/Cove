//
//  MutualsView.swift
//  Cove
//

import SwiftUI
import Kingfisher

struct MutualsView: View {
    @EnvironmentObject var appController: AppController

    // Use the shared instance from AppController
    private var vm: MutualsViewModel {
        appController.mutualsViewModel
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

                    // Mutuals list
                    ScrollView {
                        LazyVStack(spacing: 36) {
                            if vm.mutuals.isEmpty && !vm.isLoading {
                                // No mutuals message
                                VStack(spacing: 16) {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 40))
                                        .foregroundColor(Colors.primaryDark)

                                    Text("no mutuals yet – discover new connections!")
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(Colors.primaryDark)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                            } else {
                                ForEach(vm.mutuals) { mutual in
                                    NavigationLink(destination: FriendProfileView(userId: mutual.id, initialPhotoUrl: mutual.profilePhotoUrl)) {
                                        MutualRowView(
                                            id: mutual.id,
                                            name: mutual.name,
                                            imageUrl: mutual.profilePhotoUrl,
                                            sharedCoveCount: mutual.sharedCoveCount,
                                            isPending: vm.pendingRequests.contains(mutual.id),
                                            onRequest: {
                                                vm.sendFriendRequest(to: mutual.id)
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if mutual.id == vm.mutuals.last?.id {
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
                            vm.refreshMutuals {
                                continuation.resume()
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            // Load mutuals if not already cached (will use cached data if available)
            vm.loadNextPageIfStale()
        }
    }
}

struct MutualRowView: View {
    let id: String
    let name: String
    var imageUrl: URL? = nil
    var sharedCoveCount: Int = 0
    var isPending: Bool = false
    var onRequest: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Profile image (if URL exists, load with KFImage; otherwise placeholder)
            if let url = imageUrl {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image("default_user_pfp")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                // Friend's name
                Text(name)
                    .font(.LibreBodoni(size: 16))
                    .foregroundStyle(Color.black)

                // Shared cove count
                Text("\(sharedCoveCount) shared cove\(sharedCoveCount == 1 ? "" : "s")")
                    .font(.LibreBodoni(size: 12))
                    .foregroundStyle(Color.black.opacity(0.6))
            }

            Spacer()

            // "Request" / "Pending" button
            if isPending {
                ActionButton.pending()
            } else {
                ActionButton.request {
                    onRequest?()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MutualsView()
        .environmentObject(AppController.shared)
}
