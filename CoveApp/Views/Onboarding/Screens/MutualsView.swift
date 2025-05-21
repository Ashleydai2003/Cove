//
//  MutualsView.swift
//  Cove
//

import SwiftUI

struct MutualsView: View {
    @EnvironmentObject var appController: AppController
    @State private var bio: String = ""
    @State private var showError = false

    // MARK: – State for static API flow
    @State private var matches: [ContactMatcher.MatchedUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSheet = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Colors.faf8f4
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    // Back button
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)

                    // Title & description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("add friends")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 35))

                        Text("cove is a secure, curated network. let us help you find your friends of friends.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))

                        Text("we never share phone numbers.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))

                        Text("add at least 5 friends. the more genuine friends you add, the better cove will work for you. we ONLY see the contacts you choose.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Choose contacts button
                    Button {
                        startMatching()
                    } label: {
                        Text("choose friends from contacts")
                            .font(.LibreBodoni(size: 16))
                            .foregroundStyle(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
                    }
                    .padding(.bottom, 40)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()

                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView("Looking up friends…")
                        .padding()
                        .background(Color.white.cornerRadius(10))
                }
            }
            // Results sheet
            .sheet(isPresented: $showSheet) {
                NavigationView {
                    Group {
                        if let error = errorMessage {
                            VStack(spacing: 20) {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                Button("Close") {
                                    showSheet = false
                                }
                            }
                            .padding()
                        } else {
                            List(matches) { user in
                                HStack {
                                    AsyncImage(url: user.imageURL) { img in
                                        img.resizable()
                                           .clipShape(Circle())
                                    } placeholder: {
                                        Circle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 44, height: 44)

                                    Text(user.name)
                                }
                            }
                            .navigationTitle("Matches")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        showSheet = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appController.errorMessage)
        }
    }

    private func startMatching() {
        isLoading = true
        errorMessage = nil
        matches = []

        ContactMatcher.matchContacts { result in
            isLoading = false
            switch result {
            case .success(let users):
                matches = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
            showSheet = true
        }
    }
}

// Preview
#Preview {
    MutualsView()
        .environmentObject(AppController.shared)
}
