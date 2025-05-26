//
//  AddFriendsSheet.swift
//  Cove
//

import SwiftUI

// MARK: - Row for each existing user 
private struct MatchedUserRow: View {
    let user: ContactMatcher.MatchedUser
    
    var body: some View {
        HStack {
            AsyncImage(url: user.profilePhotoUrl) { img in
                img.resizable().clipShape(Circle())
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(maxWidth: 80, maxHeight: 80)

            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.LibreBodoni(size: 16))
            }
            .padding(.leading, 16)

            Spacer()

            Button(action: {
                // TODO: Implement add friend action
            }) {
                Text("request")
                    .font(.LibreBodoni(size: 14))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 30)
                    .background(Colors.primaryDark)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View for when no matches are found
private struct NoMatchesView: View {
    let onDismiss: () -> Void
    let isLoading: Bool
    @Binding var showError: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Your Friends are not on Cove yet!")
                    .font(.LibreBodoni(size: 24))
                    .foregroundStyle(Colors.primaryDark)
                    .multilineTextAlignment(.center)
                
                Text("Send them an Invite?")
                    .font(.LeagueSpartan(size: 16))
                    .foregroundStyle(.black)
                
                Button(action: {
                    // TODO: Implement invite action
                    // on success, finish the onboarding flow
                    // TODO: also on dismiss, we should finish the onboarding flow
                    // or have a finished button 
                    Onboarding.completeOnboarding { success in
                        if !success {
                            showError = true
                        }
                    }
                }) {
                    Text("Send Invite")
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
}

struct AddFriendsSheet: View {
    let serverMatches: [ContactMatcher.MatchedUser]
    let showingNoMatches: Bool
    let isLoading: Bool
    let onDismiss: () -> Void
    @Binding var showError: Bool
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            if showingNoMatches {
                NoMatchesView(
                    onDismiss: onDismiss,
                    isLoading: isLoading,
                    showError: $showError
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
                        .padding(.horizontal, 40)
                    }
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
        showError: .constant(false)
    )
} 
