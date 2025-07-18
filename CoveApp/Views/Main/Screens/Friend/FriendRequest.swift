//
//  RequestsView.swift
//  Cove
//
//  Screen of user's friend requests.

import SwiftUI
import Kingfisher

// MARK: — Main View

struct RequestsView: View {
    @EnvironmentObject private var appController: AppController
    @ObservedObject private var vm: RequestsViewModel = AppController.shared.requestsViewModel

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

                    // Requests list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Requests count header
                            if !vm.requests.isEmpty {
                                Text("\(vm.requests.count) requests")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 18))
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                            }

                            // Members list
                            LazyVStack(spacing: 12) {
                                if vm.requests.isEmpty && !vm.isLoading {
                                    // No requests message
                                    VStack(spacing: 16) {
                                        Image(systemName: "person.2.slash")
                                            .font(.system(size: 40))
                                            .foregroundColor(Colors.primaryDark)

                                        Text("no friend requests – you’re all caught up!")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                } else {
                                    ForEach(vm.requests) { req in
                                        NavigationLink(destination: FriendProfileView(userId: req.sender.id, initialPhotoUrl: req.sender.profilePhotoUrl)) {
                                            RequestRowView(
                                                id: req.sender.id,
                                                name: req.sender.name,
                                                imageUrl: req.sender.profilePhotoUrl,
                                                onConfirm: {
                                                    vm.accept(req)
                                                },
                                                onDelete: {
                                                    vm.reject(req)
                                                }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .onAppear {
                                            if req.id == vm.requests.last?.id {
                                                vm.loadNextPage()
                                            }
                                        }
                                    }
                                }
                            }

                            // Loading indicator
                            if vm.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Colors.primaryDark)
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }

                            Spacer(minLength: 24)
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
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            // Load friend requests if not already cached (will use cached data if available)
            vm.loadNextPageIfStale()
        }
    }
}

// MARK: — Subview for each row

struct RequestRowView: View {
    let id: String
    let name: String
    var imageUrl: URL? = nil
    var onConfirm: (() -> Void)? = nil
    var onDelete:  (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            if let url = imageUrl {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Image("default_user_pfp")
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }

            // Member info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoniBold(size: 16))
            }

            Spacer()

            // Action buttons - Instagram style (shorter width)
            HStack(spacing: 8) {
                if let confirm = onConfirm {
                    ActionButton(
                        title: "confirm",
                        width: 80, // Shorter Instagram-style width
                        height: 32,
                        backgroundColor: Colors.primaryDark,
                        textColor: .white,
                        font: .LibreBodoni(size: 14),
                        cornerRadius: 8
                    ) {
                        confirm()
                    }
                }

                if let delete = onDelete {
                    ActionButton(
                        title: "delete",
                        width: 80, // Shorter Instagram-style width
                        height: 32,
                        backgroundColor: Color.gray.opacity(0.3),
                        textColor: Colors.primaryDark,
                        font: .LibreBodoni(size: 14),
                        cornerRadius: 8
                    ) {
                        delete()
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .background(
            NavigationLink(destination: FriendProfileView(userId: id)) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .opacity(0)
        )
    }
}

// MARK: — Preview

struct RequestsView_Previews: PreviewProvider {
    // placeholder request DTOs
    static let sampleRequests: [RequestDTO] = [
        .init(id: "1", sender: .init(id: "1", name: "angela nguyen", profilePhotoUrl: nil), createdAt: "2025-01-01T00:00:00.000Z"),
        .init(id: "2", sender: .init(id: "2", name: "willa r baker", profilePhotoUrl: nil), createdAt: "2025-01-01T00:00:00.000Z"),
        .init(id: "3", sender: .init(id: "3", name: "nina boord", profilePhotoUrl: nil), createdAt: "2025-01-01T00:00:00.000Z"),
        .init(id: "4", sender: .init(id: "4", name: "felix roberts", profilePhotoUrl: nil), createdAt: "2025-01-01T00:00:00.000Z"),
        .init(id: "5", sender: .init(id: "5", name: "tyler schuman", profilePhotoUrl: nil), createdAt: "2025-01-01T00:00:00.000Z")
    ]

    static var previews: some View {
        GeometryReader { _ in
            ZStack {
                Colors.faf8f4.ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Text("requests")
                            .font(.LibreBodoniBold(size: 35))
                            .foregroundStyle(Colors.primaryDark)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)

                    // Rows
                    ScrollView {
                        LazyVStack(spacing: 36) {
                            ForEach(sampleRequests) { req in
                                RequestRowView(
                                    id: req.sender.id,
                                    name: req.sender.name,
                                    imageUrl: req.sender.profilePhotoUrl,
                                    onConfirm: {},
                                    onDelete:  {}
                                )
                            }
                        }
                        .padding(.top, 30)
                    }

                    Spacer(minLength: 0)
                }
                .safeAreaPadding()
            }
        }
        .previewDevice("iPhone 13")
        .environmentObject(AppController.shared)
    }
}

