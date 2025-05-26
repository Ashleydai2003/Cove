//
//  MutualsView.swift
//  Cove
//

import SwiftUI
import Contacts

// MARK: - Models
private struct LocalContact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
}

// MARK: - View Components
private struct HeaderView: View {
    var body: some View {
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
    }
}

private struct ContactsButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
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
}

private struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.25).ignoresSafeArea()
        ProgressView().padding().background(Color.white.cornerRadius(10))
    }
}

private struct ContactRow: View {
    let contact: LocalContact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(contact.name)
            Spacer()
            Text(contact.phone)
                .font(.caption)
                .foregroundColor(.gray)
            if isSelected {
                Image(systemName: "checkmark").foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}


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
            .frame(width: 44, height: 44)

            VStack(alignment: .leading) {
                Text(user.name)
                Text(user.phone)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                // TODO: Implement add friend action
            }) {
                Text("Add Friend")
                    .font(.LeagueSpartan(size: 14))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
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

// MARK: - Main View
struct MutualsView: View {
    @EnvironmentObject var appController: AppController
    
    // MARK: – State
    @State private var serverMatches: [ContactMatcher.MatchedUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSheet = false
    @State private var showError = false
    @State private var showingNoMatches = false
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button { appController.path.removeLast() } label: {
                        Images.backArrow
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                HeaderView()
                Spacer()
                ContactsButton(action: processAllContacts, isLoading: isLoading)
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
            
            if isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Finding your friends...")
                        .font(.LeagueSpartan(size: 24))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            NavigationView {
                if showingNoMatches {
                    NoMatchesView(
                        onDismiss: { showSheet = false },
                        isLoading: isLoading,
                        showError: $showError
                    )
                } else {
                    List(serverMatches) { user in
                        MatchedUserRow(user: user)
                    }
                    .navigationTitle("add friends on cove!")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showSheet = false }
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred. Please try again.")
        }
    }
    
    // MARK: – Helpers
    private func processAllContacts() {
        isLoading = true
        errorMessage = nil
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, err in
            guard granted, err == nil else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Contacts access denied"
                    showError = true
                }
                return
            }
            
            // Move contacts processing to background thread
            DispatchQueue.global(qos: .userInitiated).async {
                let req = CNContactFetchRequest(keysToFetch: [
                    CNContactPhoneNumbersKey as CNKeyDescriptor
                ])
                
                var phones: [String] = []
                try? store.enumerateContacts(with: req) { contact, _ in
                    contact.phoneNumbers.forEach { phoneNumber in
                        if let e164 = e164(phoneNumber.value.stringValue) {
                            phones.append(e164)
                        }
                    }
                }
                
                // Match phones with server to find existing accounts
                ContactMatcher.matchPhones(phones) { result in
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isLoading = false
                            switch result {
                            case .success(let users):
                                serverMatches = users
                                showingNoMatches = users.isEmpty
                                showSheet = true
                            case .failure(let err):
                                errorMessage = err.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func e164(_ raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        switch digits.count {
        case 10:               return "+1" + digits
        case 11 where digits.first == "1": return "+" + digits
        default:               return nil
        }
    }
}

#Preview {
    MutualsView()
        .environmentObject(AppController.shared)
}
