//
//  MutualsView.swift
//  Cove
//

import SwiftUI
import Contacts

struct MutualsView: View {
    @EnvironmentObject var appController: AppController

    // MARK: – Local contacts
    private struct LocalContact: Identifiable {
        let id = UUID()
        let name: String
        let phone: String
    }
    @State private var localContacts: [LocalContact] = []
    @State private var selectedLocalIDs = Set<UUID>()

    // MARK: – Server matches
    @State private var serverMatches: [ContactMatcher.MatchedUser] = []

    // MARK: – UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSheet = false
    @State private var showingLocalPicker = true

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

                Button { fetchLocalContacts() } label: {
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

            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().padding().background(Color.white.cornerRadius(10))
            }
        }
        .sheet(isPresented: $showSheet) {
            NavigationView {
                Group {
                    if let err = errorMessage {
                        VStack(spacing: 20) {
                            Text("Error: \(err)").foregroundColor(.red)
                            Button("Close") { showSheet = false }
                        }
                        .padding()

                    } else if showingLocalPicker {
                        // Local picker
                        List(localContacts) { c in
                            HStack {
                                Text(c.name)
                                Spacer()
                                Text(c.phone).font(.caption).foregroundColor(.gray)
                                if selectedLocalIDs.contains(c.id) {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedLocalIDs.contains(c.id) {
                                    selectedLocalIDs.remove(c.id)
                                } else {
                                    selectedLocalIDs.insert(c.id)
                                }
                            }
                        }
                        .navigationTitle("Select contacts")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showSheet = false }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Share (\(selectedLocalIDs.count))") {
                                    postSelectedContacts()
                                }
                                .disabled(selectedLocalIDs.isEmpty)
                            }
                        }

                    } else {
                        // Server matches
                        List(serverMatches) { u in
                            HStack {
                                AsyncImage(url: u.profilePhotoUrl) { img in
                                    img.resizable().clipShape(Circle())
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 44, height: 44)

                                VStack(alignment: .leading) {
                                    Text(u.name)
                                    Text(u.phone)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .navigationTitle("Matches")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showSheet = false }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: – Helpers

    private func fetchLocalContacts() {
        isLoading = true
        errorMessage = nil
        showingLocalPicker = true
        localContacts.removeAll()
        selectedLocalIDs.removeAll()

        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, err in
            DispatchQueue.main.async {
                isLoading = false
                guard granted, err == nil else {
                    errorMessage = "Contacts access denied"
                    showSheet = true
                    return
                }
                let req = CNContactFetchRequest(keysToFetch: [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor,
                    CNContactPhoneNumbersKey as CNKeyDescriptor
                ])
                var arr: [LocalContact] = []
                try? store.enumerateContacts(with: req) { raw, _ in
                    let name = [raw.givenName, raw.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    raw.phoneNumbers.forEach {
                        arr.append(LocalContact(name: name,
                                                phone: $0.value.stringValue))
                    }
                }
                localContacts = arr
                showSheet = true
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

    private func postSelectedContacts() {
        isLoading = true
        errorMessage = nil

        let phones = localContacts
            .filter { selectedLocalIDs.contains($0.id) }
            .compactMap { e164($0.phone) }

        ContactMatcher.matchPhones(phones) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let users):
                    serverMatches = users
                    showingLocalPicker = false
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

// Preview
#Preview {
    MutualsView()
        .environmentObject(AppController.shared)
}
