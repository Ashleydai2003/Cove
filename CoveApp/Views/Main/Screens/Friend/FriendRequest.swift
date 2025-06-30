//
//  RequestsView.swift
//  Cove
//
//  Screen of user's friend requests.

import SwiftUI

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requests: [RequestDTO] = []
    @Published var nextCursor: String?
    @Published var hasMore = true
    @Published var isLoading = false {
        didSet { if isLoading { loadingStart = Date() } }
    }
    @Published var errorMessage: String?
    
    private let pageSize = 7
    private var loadingStart: Date?
    
    init() {
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        FriendRequests.fetch(cursor: nextCursor, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let resp):
                self.requests.append(contentsOf: resp.requests)
                self.hasMore = resp.pagination.nextCursor != nil
                self.nextCursor = resp.pagination.nextCursor
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func accept(_ req: RequestDTO) {
        FriendRequests.resolve(requestId: req.id, action: "ACCEPT") { [weak self] result in
            switch result {
            case .success:
                self?.requests.removeAll { $0.id == req.id }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func reject(_ req: RequestDTO) {
        FriendRequests.resolve(requestId: req.id, action: "REJECT") { [weak self] result in
            switch result {
            case .success:
                self?.requests.removeAll { $0.id == req.id }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: — Main View

struct RequestsView: View {
    @EnvironmentObject var appController: AppController
    @StateObject private var vm = RequestsViewModel()
    
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
                    ScrollView {
                        LazyVStack(spacing: 36) {
                            if vm.requests.isEmpty && !vm.isLoading {
                                // No requests message
                                VStack(spacing: 16) {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("no requests yet!")
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                            } else {
                                ForEach(vm.requests) { req in
                                    RequestRowView(
                                        name: req.sender.name,
                                        imageUrl: req.sender.profilePhotoUrl,
                                        onConfirm: { vm.accept(req) },
                                        onDelete:  { vm.reject(req) }
                                    )
                                    .onAppear {
                                        if req.id == vm.requests.last?.id {
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
    }
}

// MARK: — Subview for each row

struct RequestRowView: View {
    let name: String
    var imageUrl: URL? = nil
    var onConfirm: (() -> Void)? = nil
    var onDelete:  (() -> Void)? = nil
    
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
            
            if let confirm = onConfirm {
                Button(action: confirm) {
                    Text("confirm")
                        .font(.LibreBodoni(size: 10))
                        .frame(width: 65, height: 20)
                        .background(Colors.primaryDark)
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }
            }
            
            if let delete = onDelete {
                Button(action: delete) {
                    Text("delete")
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


