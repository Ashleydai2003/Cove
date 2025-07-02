//
//  MutualsView.swift
//  Cove
//

import SwiftUI

struct MutualsView: View {
    @EnvironmentObject var appController: AppController
    
    // Use the shared instance from AppController
    private var viewModel: MutualsViewModel {
        appController.mutualsViewModel
    }

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            VStack(spacing: 0) {
                

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
                    .padding(.top, 100)
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
                    .padding(.top, 100)
                } else if viewModel.mutuals.isEmpty && !viewModel.isLoading {
                    // No mutuals message
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("no mutuals yet!")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
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
                                        ActionButton.pending()
                                    } else {
                                        ActionButton.request {
                                            viewModel.sendFriendRequest(to: mutual.id)
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
        .onAppear {
            viewModel.loadNextPageIfStale()
        }
    }
}

// MARK: — Preview

struct MutualsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualsView()
            .environmentObject(AppController.shared)
            .previewDevice("iPhone 13")
    }
}
