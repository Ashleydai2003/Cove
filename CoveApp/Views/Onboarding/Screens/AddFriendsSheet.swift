//
//  AddFriendsSheet.swift
//  Cove
//

import SwiftUI

// MARK: - Row for each existing user
private struct MatchedUserRow: View {
    let user: ContactMatcher.MatchedUser
    @State private var requestSent = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        HStack {
            AsyncImage(url: user.profilePhotoUrl) { img in
                img.resizable().clipShape(Circle())
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(maxWidth: 80, maxHeight: 80)

            Text(user.name)
                .frame(maxWidth: 150, alignment: .leading)
                .font(.LibreBodoni(size: 16))
                .padding(.leading, 15)

            Spacer()

            Button(action: {
                if requestSent {
                    Onboarding.removeFriendRequest(userId: user.id)
                } else {
                    Onboarding.addFriendRequest(userId: user.id)
                }
                requestSent.toggle()
            }) {
                Text(requestSent ? "unrequest" : "request")
                    .font(.LibreBodoni(size: 14))
                    .frame(maxWidth: 100)
                    .padding(.vertical, 6)
                    .background(requestSent ? Color.gray : Colors.primaryDark)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - View for when no matches are found
private struct NoMatchesView: View {
    let onDismiss: () -> Void
    let isLoading: Bool
    @Binding var showError: Bool
    let appController: AppController

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("your friends are not on cove yet!")
                    .font(.LibreBodoni(size: 24))
                    .foregroundStyle(Colors.primaryDark)
                    .multilineTextAlignment(.center)

                Text("send them an invite?")
                    .font(.LeagueSpartan(size: 16))
                    .foregroundStyle(.black)

                Button(action: {
                    // Complete onboarding and navigate to data loading
                    completeOnboarding()
                }) {
                    Text("send invite")
                        .font(.LeagueSpartan(size: 16))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Colors.primaryDark)
                        .cornerRadius(8)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                }
            }

            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView()
                    .padding()
                    .background(Color.white.cornerRadius(10))
            }
        }
    }

    private func completeOnboarding() {
        Onboarding.completeOnboarding { success in
            DispatchQueue.main.async {
                if success {
                    // Navigate to data loading screen
                    appController.path = [.pluggingIn]
                    onDismiss()
                } else {
                    // Show error if onboarding fails
                    showError = true
                }
            }
        }
    }
}

// MARK: - Main view
struct AddFriendsSheet: View {
    let serverMatches: [ContactMatcher.MatchedUser]
    let showingNoMatches: Bool
    let isLoading: Bool
    let onDismiss: () -> Void
    @Binding var showError: Bool
    let appController: AppController

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            if showingNoMatches {
                NoMatchesView(
                    onDismiss: {
                        Onboarding.clearPendingFriendRequests()
                        onDismiss()
                    },
                    isLoading: isLoading,
                    showError: $showError,
                    appController: appController
                )
            } else {
                VStack {
                    Text("add friends on cove!")
                        .font(.LibreBodoni(size: 24))
                        .foregroundStyle(Colors.primaryDark)
                        .padding(.top, 80)

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(serverMatches) { user in
                                MatchedUserRow(user: user)
                            }
                        }
                        .padding(.horizontal, 30)
                    }

                    Button(action: {
                        // Complete onboarding and navigate to data loading
                        completeOnboarding()
                    }) {
                        Text("done")
                            .font(.LeagueSpartan(size: 16))
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Colors.primaryDark)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 30)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done", action: {
                            Onboarding.clearPendingFriendRequests()
                            onDismiss()
                        })
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        Onboarding.completeOnboarding { success in
            DispatchQueue.main.async {
                if success {
                    // Navigate to data loading screen
                    appController.path = [.pluggingIn]
                    onDismiss()
                } else {
                    // Show error if onboarding fails
                    showError = true
                }
            }
        }
    }
}

#Preview {
    AddFriendsSheet(
        serverMatches: [],
        showingNoMatches: true,
        isLoading: false,
        onDismiss: {},
        showError: .constant(false),
        appController: AppController.shared
    )
}
