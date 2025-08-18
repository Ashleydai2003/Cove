//
//  CreateCoveView.swift
//  Cove
//
//  Created by Assistant

import SwiftUI

// MARK: - Main View
struct CreateCoveView: View {
    // MARK: - Properties
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewCoveModel()

    @FocusState private var isFocused: Bool
    @State private var showInviteSheet = false

    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()

            VStack {
                HStack {
                    Button("cancel") { dismiss() }
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        coveNameSection
                        imagePickerSection

                        locationSection
                        descriptionSection
                        inviteButtonSection
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 50)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.coverPhoto)
        }
        .sheet(isPresented: $viewModel.showLocationPicker) {
            LocationSearchView(completion: { location in
                viewModel.location = location
            })
        }
        .sheet(isPresented: $showInviteSheet) {
            SendInvitesView(
                coveId: "", // Will be set during cove creation
                coveName: viewModel.name.isEmpty ? "Untitled Cove" : viewModel.name,
                sendAction: {
                    showInviteSheet = false
                },
                onDataSubmit: { phoneNumbers, message in
                    viewModel.storeInviteData(phoneNumbers: phoneNumbers, message: message)
                },
                initialPhoneNumbers: viewModel.invitePhoneNumbers,
                initialMessage: viewModel.inviteMessage
            )
        }
        .navigationBarBackButtonHidden()
        .onTapGesture {
            isFocused = false
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - View Components
extension CreateCoveView {
    // MARK: - Header
    private var headerView: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()

                Image("cove_logo_circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.leading, -10)

                Spacer()
            }
            .padding(.horizontal, 16)

            Text("create a cove")
                .font(.Lugrasimo(size: 35))
                .foregroundColor(Colors.primaryDark)
        }
    }

    // MARK: - Cove Name Section
    private var coveNameSection: some View {
        VStack {
            ZStack(alignment: .center) {
                if viewModel.name.isEmpty {
                    Text("untitled cove")
                        .foregroundColor(.white)
                        .font(.LibreBodoniBold(size: 22))
                }

                TextField("untitled cove", text: $viewModel.name)
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 22))
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .padding(16)
        }
        .background(Colors.primaryDark)
        .cornerRadius(10)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("describe your cove...")
                        .foregroundColor(.gray)
                        .font(.LibreBodoni(size: 16))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $viewModel.description)
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoni(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .focused($isFocused)
            }
            .padding(12)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.top, 8)
    }

    // MARK: - Image Picker Section
    private var imagePickerSection: some View {
        Button {
            viewModel.showImagePicker = true
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .background(
                        Circle()
                            .fill(Color.white)
                    )

                if let coverPhoto = viewModel.coverPhoto {
                    Image(uiImage: coverPhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                } else {
                    VStack(spacing: 8) {
                        Text("choose emoji")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                        Text("or upload icon")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Location Section
    private var locationSection: some View {
        Button {
            viewModel.showLocationPicker = true
        } label: {
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)

                Text("location")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .padding(.leading, 16)

                Spacer()

                Text(viewModel.location ?? "")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .lineLimit(2)
                    .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
            )
        }
        .padding(.top, 16)
    }

    // MARK: - Invite Button Section
    private var inviteButtonSection: some View {
        Button {
            showInviteSheet = true
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)

                Text("invite")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .padding(.leading, 16)

                Spacer()

                if viewModel.hasInvites {
                    HStack(spacing: 8) {
                        Text("\(viewModel.invitePhoneNumbers.count) added")
                            .foregroundStyle(Color.white)
                            .font(.LibreBodoni(size: 14))

                        Button(action: {
                            viewModel.clearInviteData()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Colors.primaryDark)
                        }
                    }
                    .padding(.trailing, 24)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.hasInvites ? Colors.primaryDark : Color(red: 0.4, green: 0.2, blue: 0.2))
            )
        }
        .padding(.top, 16)
    }

    // MARK: - Create Button
    private var createButtonView: some View {
        Button {
            viewModel.submitCove { success in
                DispatchQueue.main.async {
                if success {
                    // Refresh the cove feed to show the new cove
                    appController.refreshCoveFeedAfterCreation()
                        
                        // Add a small delay to ensure UI updates are complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                        }
                    }
                    // If failed, error message is already set in viewModel
                }
            }
        } label: {
            if viewModel.isSubmitting {
                ProgressView()
                    .tint(.black)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
            } else {
                Text(viewModel.hasInvites ? "create & invite" : "create")
                    .foregroundStyle(!viewModel.isFormValid ? Color.gray : Color.black)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Color.white)
                    )
            }
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        .padding(.top, 24)
    }
}

#Preview {
    CreateCoveView()
        .environmentObject(AppController.shared)
}
