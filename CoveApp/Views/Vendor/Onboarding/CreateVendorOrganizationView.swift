//
//  CreateVendorOrganizationView.swift
//  Cove
//
//  Form for creating a new vendor organization
//

import SwiftUI
import PhotosUI

struct CreateVendorOrganizationView: View {
    @EnvironmentObject var vendorController: VendorController
    
    @State private var organizationName: String = ""
    @State private var website: String = ""
    @State private var primaryContactEmail: String = ""
    @State private var selectedCity: String = ""
    @State private var showCityPicker: Bool = false
    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // Photo upload states
    @State private var coverPhoto: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case organizationName, website, email
    }
    
    // Available cities (from user onboarding)
    let cities = [
        "Boston", "New York City", "Philadelphia", "Washington D.C.", "Atlanta",
        "Miami", "Chicago", "Detroit", "Dallas", "Houston", "Austin",
        "Phoenix", "Denver", "Seattle", "Portland", "San Francisco",
        "Los Angeles", "San Diego"
    ].sorted()
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
            VStack {
                // Back button
                HStack {
                    Button {
                        vendorController.path.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Colors.primaryDark)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // Header
                VStack(alignment: .leading) {
                    Text("create your \norganization")
                        .font(.LibreBodoni(size: 40))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("provide your organization's information")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)
                
                // Form fields in ScrollView
                ScrollView {
                    VStack(spacing: 24) {
                        // Organization name
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("organization name", text: $organizationName)
                                .font(.LibreCaslon(size: 25))
                                .focused($focusedField, equals: .organizationName)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 10)
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        // Website (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("website (optional)", text: $website)
                                .font(.LibreCaslon(size: 25))
                                .focused($focusedField, equals: .website)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 10)
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        // Primary Contact Email
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("primary contact email", text: $primaryContactEmail)
                                .font(.LibreCaslon(size: 25))
                                .focused($focusedField, equals: .email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 10)
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        // City selection
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                focusedField = nil // Dismiss keyboard
                                showCityPicker = true
                            }) {
                                HStack {
                                    Text(selectedCity.isEmpty ? "select city" : selectedCity)
                                        .font(.LibreCaslon(size: 25))
                                        .foregroundColor(selectedCity.isEmpty ? Color.gray : Color.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Colors.primaryDark)
                                }
                                .padding(.horizontal, 10)
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        // Cover Photo Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("cover photo (optional)")
                                .font(.LeagueSpartan(size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    if let coverPhoto = coverPhoto {
                                        Image(uiImage: coverPhoto)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                            )
                                            .overlay(
                                                VStack(spacing: 8) {
                                                    Image(systemName: "camera")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                                                    Text("add cover photo")
                                                        .font(.LeagueSpartan(size: 14))
                                                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                                                }
                                            )
                                            .frame(width: 200, height: 120)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if showError {
                            Text(errorMessage)
                                .font(.LeagueSpartan(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 40)
                }
                
                // Create button
                SignOnButton(text: isCreating ? "creating..." : "create organization") {
                    createOrganization()
                }
                .disabled(!canCreate || isCreating)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .sheet(isPresented: $showCityPicker) {
            NavigationView {
                List(cities, id: \.self) { city in
                    Button(action: {
                        selectedCity = city
                        showCityPicker = false
                    }) {
                        HStack {
                            Text(city)
                                .font(.LeagueSpartan(size: 16))
                                .foregroundColor(.black)
                            Spacer()
                            if selectedCity == city {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Colors.primaryDark)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Select City")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showCityPicker = false
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            focusedField = .organizationName
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    coverPhoto = image
                }
            }
        }
    }
    
    private var canCreate: Bool {
        !organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !primaryContactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCity.isEmpty
    }
    
    private func createOrganization() {
        guard canCreate else { return }
        
        isCreating = true
        showError = false
        errorMessage = ""
        
        let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
        
        VendorNetworkManager.shared.createVendorOrganization(
            organizationName: organizationName.trimmingCharacters(in: .whitespacesAndNewlines),
            website: trimmedWebsite.isEmpty ? nil : trimmedWebsite,
            primaryContactEmail: primaryContactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            city: selectedCity,
            coverPhoto: coverPhoto
        ) { result in
            isCreating = false
            
            switch result {
                case .success(let response):
                    // Store the new vendor code to show later
                    vendorController.newVendorCode = response.vendor.code
                    vendorController.path.append(.userDetails)
                
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
                Log.error("Error creating organization: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    CreateVendorOrganizationView()
        .environmentObject(VendorController.shared)
}
