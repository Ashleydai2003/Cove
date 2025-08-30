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
    @FocusState private var isCityFocused: Bool
    @State private var showInviteSheet = false
    @State private var showCityInput = false
    @State private var showCityDropdown = false
    @State private var searchCity: String = ""

    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        coveNameSection
                        imagePickerSection

                        citySection
                        descriptionSection
                        inviteButtonSection
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }

            }
            .padding(.top, 0)
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
        ZStack {
            // Center title
            Text("create a cove ✨")
                .font(.LibreBodoni(size: 18))
                .foregroundColor(Colors.primaryDark)

            // Leading/trailing actions
            HStack {
                Button("cancel") { dismiss() }
                    .font(.LibreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Cove Name Section
    private var coveNameSection: some View {
        ZStack(alignment: .leading) {
            // Lightweight translucent background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            // Text field with placeholder
            ZStack(alignment: .leading) {
                if viewModel.name.isEmpty {
                    Text("name your cove")
                        .foregroundColor(Color.black.opacity(0.35))
                        .font(.LibreBodoniBold(size: 20))
                        .padding(.horizontal, 14)
                }

                TextField("name your cove", text: $viewModel.name)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoniBold(size: 20))
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        ZStack(alignment: .topLeading) {
            // Lightweight translucent background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            // Placeholder + editor
            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("describe your cove...")
                        .foregroundColor(Color.black.opacity(0.35))
                        .font(.LibreBodoni(size: 16))
                        .padding(.top, 12)
                        .padding(.leading, 14)
                }
                TextEditor(text: $viewModel.description)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoni(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96, maxHeight: 140)
                    .focused($isFocused)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Image Picker Section
    private var imagePickerSection: some View {
        HStack {
            Spacer()
            Button {
                viewModel.showImagePicker = true
            } label: {
                ZStack {
                    if let coverPhoto = viewModel.coverPhoto {
                        // Square image preview with rounded corners and subtle border
                        Image(uiImage: coverPhoto)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                    } else {
                        // Lightweight square placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                            .overlay(
                                Text("select photo")
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(Color.black.opacity(0.45))
                            )
                            .frame(width: 180, height: 180)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 16)
    }

    // MARK: - City Section (typeahead)
    private var citySection: some View {
        VStack(spacing: 8) {
            // Red bar with either label or text field on top
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
                    .frame(maxWidth: .infinity, minHeight: 46, maxHeight: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    Image(systemName: "location")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white)
                        .padding(.leading, 24)

                    if showCityInput {
                        // Type here over the red bar
                        ZStack(alignment: .leading) {
                            if searchCity.isEmpty {
                                Text("city")
                                    .foregroundColor(Color.white)
                                    .font(.LibreBodoniBold(size: 16))
                            }
                            TextField("", text: $searchCity)
                                .font(.LibreBodoniBold(size: 16))
                                .foregroundColor(Color.white)
                                .keyboardType(.alphabet)
                                .focused($isCityFocused)
                                .onChange(of: searchCity) { oldValue, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                    searchCity = trimmed
                                    if showCityInput && isCityFocused && !trimmed.isEmpty && trimmed != oldValue {
                                        showCityDropdown = true
                                    } else if trimmed.isEmpty {
                                        showCityDropdown = false
                                    }
                                }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                    } else {
                        // Initial static label; tap to activate input
                        HStack {
                            Text(viewModel.location?.isEmpty == false ? viewModel.location! : "city")
                                .foregroundStyle(Color.white)
                                .font(.LibreBodoniBold(size: 16))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 16)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showCityInput = true
                                searchCity = viewModel.location ?? ""
                            }
                            isCityFocused = true
                            showCityDropdown = !(searchCity.isEmpty)
                        }
                        .padding(.trailing, 16)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Red dropdown suggestions underneath
            if showCityDropdown {
                VStack(spacing: 0) {
                    ForEach(filteredCities, id: \.self) { city in
                        Button {
                            viewModel.location = city
                            // Clear search to avoid re-triggering dropdown onChange
                            searchCity = ""
                            showCityDropdown = false
                            showCityInput = false
                            isCityFocused = false
                        } label: {
                            HStack {
                                Text(city)
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(Colors.background)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(Colors.primaryDark)

                        if city != filteredCities.last {
                            Divider().background(Colors.background.opacity(0.15))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 16)
    }

    private var filteredCities: [String] {
        CitiesData.filteredCities(searchQuery: searchCity)
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
                    .tint(Colors.background)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.primaryDark)
                    )
            } else {
                Text(viewModel.hasInvites ? "create & invite" : "create")
                    .foregroundStyle(!viewModel.isFormValid ? Color.gray : Colors.background)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Colors.primaryDark)
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
