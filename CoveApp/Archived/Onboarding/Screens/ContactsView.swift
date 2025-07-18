//
//  ContactsView.swift
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
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
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
            .disabled(isLoading)

            Button(action: onSkip) {
                Text("skip")
                    .font(.LeagueSpartan(size: 14))
                    .foregroundStyle(Colors.primaryDark)
                    .underline()
            }
            .disabled(isLoading)
        }
        .padding(.bottom, 40)
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

// MARK: - Main View
struct ContactsView: View {
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
            OnboardingBackgroundView()

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
                ContactsButton(
                    action: processAllContacts,
                    isLoading: isLoading,
                    onSkip: {
                        // Complete onboarding and navigate to data loading
                        completeOnboarding()
                    }
                )
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
            AddFriendsSheet(
                serverMatches: serverMatches,
                showingNoMatches: showingNoMatches,
                isLoading: isLoading,
                onDismiss: { showSheet = false },
                showError: $showError,
                appController: appController
            )
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

    private func completeOnboarding() {
        // Complete onboarding and navigate to data loading screen
        Onboarding.completeOnboarding { success in
            DispatchQueue.main.async {
                if success {
                    // Navigate to data loading screen
                    appController.path = [.pluggingIn]
                } else {
                    // Stay on this screen if onboarding fails
                    errorMessage = "Failed to complete onboarding"
                    showError = true
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
    ContactsView()
        .environmentObject(AppController.shared)
}
